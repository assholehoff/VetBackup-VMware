//
//  VirtualMachine.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2025-12-04.
//

import Combine
import Foundation
import os
import RegexBuilder
import UserNotifications

/**
 * The VirtualMachine class is the interface to **VMware Fusion** and its VM through `vmrun` processes.
 */
@MainActor
public class VirtualMachine: ObservableObject {
    /** The URL to the `.vmwarevm` bundle. This is where the `vmx` and `diskFile` is found. */
    var url: URL
    var name: String
    var vmrun: URL
    var vmxFile: VMXFile
    var diskFile: File

    /**
     * The user specified folder where the backups are stored.
     * This is also the folder where the Windows utilities output temporary files.
     */
    @Published var backupFolderURL: URL {
        didSet { self.updateLastBackupDateFromFolder() }
    }
    @Published var backupOngoing: Bool = false
    @Published var dailyBackupTime: Date? { didSet { Log.backend.debug("VirtualMachine.dailyBackupTime.didSet()") }}
    /** The date the latest backup file reflects. */
    @Published var lastBackupDate: Date?
    /** If the last attempt failed, this is `false`.  */
    @Published var lastBackupAttempt: Bool? {
        // TODO: implement result enum
        //       i.e. `fail`, `success` and `skip`
        didSet {
            Log.backend.debug("VirtualMachine.lastBackupAttempt.didSet()")
            UserDefaults.standard.set(self.lastBackupDate, forKey: "lastBackupDate")
        }
    }
    /** The date `Database.fdb` was modified in Windows, supplied by the utility in the VM */
    @Published var lastDatabaseModifiedDate: Date? {
        didSet {
            Log.backend.debug("VirtualMachine.lastDatabaseModifiedDate.didSet()")
            UserDefaults.standard.set(self.lastDatabaseModifiedDate, forKey: "lastDatabaseModifiedDate")
        }
    }

    var vmKey: String
    var vmUser: String
    var vmPasswd: String

    var vmWindowsPaths = VMWindowsPaths.defaults

    /**
     * Call this only after fetching and verifying strings and URLs from UserDefaults, Keychain and user input.
     */
    init(
        url: URL,
        run: URL,
        user: VMAuth,
        paths: VMWindowsPaths,
        settings: VMSettings
    ) {
        Log.backend.debug("VirtualMachine.init()")
        self.url = url
        self.name = String((url.lastPathComponent.removingPercentEncoding ?? url.lastPathComponent).dropLast(9))
        self.vmrun = run
        self.vmxFile = findVmxFile(inBundle: url)!
        self.diskFile = File(url: self.vmxFile.diskFileUrl(), created: nil)

        self.backupFolderURL = settings.backupFolderURL
        self.dailyBackupTime = settings.dailyBackupTime
        self.lastBackupDate = UserDefaults.standard.object(forKey: "lastBackupDate") as? Date
        self.lastDatabaseModifiedDate = UserDefaults.standard.object(forKey: "lastDatabaseModifiedDate") as? Date

        self.vmKey = user.key
        self.vmUser = user.user
        self.vmPasswd = user.passwd

        self.updateLastBackupDateFromFolder()
        self.updateDatabaseLastModifiedDate()
    }

    /**
     * Scan the backupFolder and set lastBackupDate to the newest file. Parses filename and converts that to a Date. If folder is empty, set lastBackupDate to **nil**.
     *
     *  This function creates an array of BackupFiles and is therefore slow. Since it is called only on change of backupFolder, it should not matter.
     */
    private func updateLastBackupDateFromFolder() {
        let files = listBackupFiles(in: self.backupFolderURL)
        guard !files.isEmpty, let foundDate = files.first?.date else {
            Log.backend.error("VirtualMachine.updateLastBackupDateFromFolder() guard !files.isEmpty: failed")
            self.lastBackupDate = .distantPast
            return
        }
        self.lastBackupDate = foundDate
    }

    /**
     * The actual backup routine. Any verification is up to the caller.
     *
     * Uses `vmrun` to run a utility in Windows that exports the database as a `zip` to the folder specified in `backupFolderURL`.
     */
    func backup() async -> Bool {
        Log.backend.info("VirtualMachine.backup() start")
        await MainActor.run {
            lastBackupAttempt = nil
            self.backupOngoing = true
            Log.backend.debug("VirtualMachine.backup() reset .lastBackupAttempt to nil")
            Log.backend.debug("VirtualMachine.backup() set .backupOngoing to true")
        }

        var result = false

        // setup values for concurrency
        let key = self.vmKey
        let user = self.vmUser
        let passwd = self.vmPasswd
        let vmrun = self.vmrun
        let vmx = self.vmxFile.path()
        let exe = self.vmWindowsPaths.backupDatabaseDotExe
        let database = self.vmWindowsPaths.databaseDotFdb

        // macOS notification messages
        let errorContent = UNMutableNotificationContent()
        errorContent.title = String(localized: "Backup failed")
        errorContent.subtitle = String(localized: "Backup failed on ") + Date().formatted(date: .abbreviated, time: .shortened) + " " + String(localized: "Make sure Windows is running and user is logged in")
        let errorTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let errorRequest = UNNotificationRequest(identifier: UUID().uuidString, content: errorContent, trigger: errorTrigger)

        let ongoingContent = UNMutableNotificationContent()
        ongoingContent.title = String(localized: "Backup in progress")
        ongoingContent.subtitle = String(localized: "Vetvision will close in Windows if open")
        ongoingContent.sound = UNNotificationSound.default

        let uuid = UUID().uuidString
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: uuid, content: ongoingContent, trigger: trigger)
        await MainActor.run {
            UNUserNotificationCenter.current().add(request)
        }

        let offString: String = "Error: The virtual machine is not powered on: \(vmxFile.path())\n"

        do {
            let (taskResult, output) = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(Bool, String), Error>) in
                DispatchQueue.global(qos: .userInitiated).async {
                    let backendLog = Logger(subsystem: "com.ad.vetbackup", category: "backend")
                    let task = Process()
                    let pipe = Pipe()

                    task.standardOutput = pipe
                    task.standardError = pipe
                    task.standardInput = nil
                    task.executableURL = vmrun
                    task.arguments = [
                        "-T", "fusion", "-vp", key,
                        "-gu", user, "-gp", passwd,
                        "runProgramInGuest", vmx,
                        "-activeWindow", "-interactive",
                        exe,
                        database
                    ]

                    do {
                        try task.run()
                        let data = try pipe.fileHandleForReading.readToEnd()
                        let output = String(data: data ?? Data(), encoding: .utf8) ?? ""
                        let isOff = (output == offString)
                        continuation.resume(returning: (!isOff, output))
                    } catch {
                        backendLog.error("VirtualMachine.backup() error: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
            }

            if taskResult {
                result = true
                await MainActor.run {
                    lastBackupAttempt = true
                }
            } else {
                result = false
                await MainActor.run {
                    lastBackupAttempt = false
                }
                await MainActor.run {
                    UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [uuid])
                    UNUserNotificationCenter.current().add(errorRequest)
                }
            }
        } catch {
            print("error: \(error)")
            Log.backend.error("VirtualMachine.backup() error: \(error)")
            result = false
            await MainActor.run {
                lastBackupAttempt = false
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [uuid])
                UNUserNotificationCenter.current().add(errorRequest)
            }
        }

        if result {
            let successContent = UNMutableNotificationContent()
            successContent.title = String(localized: "Backup completed")
            successContent.subtitle = String(localized: "Backup completed on ") + Date().formatted(date: .abbreviated, time: .shortened)
            let successTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            let successRequest = UNNotificationRequest(identifier: UUID().uuidString, content: successContent, trigger: successTrigger)
            await MainActor.run {
                UNUserNotificationCenter.current().add(successRequest)
            }
        }

        if result {
            await MainActor.run {
                self.updateLastBackupDateFromFolder()
            }
        }
        await MainActor.run {
            self.backupOngoing = false
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [uuid])
        }
        print("\(timeStamp()) VirtualMachine.backup() -> \(result)")
        result ? Log.backup.notice("backup process successful") : Log.backup.error("backup process failed")
        return result
    }

    /**
     * Conditionally backup the database.
     * If the database is determined to be modified since last backup, trigger the backup routine.
     */
    func backupIfNeeded() async -> Bool {
        guard self.modified() else {
            Log.backup.notice("database is unmodified, skipping backup")
            return false
        }
        return await self.backup()
    }

    /**
     * Returns **true** if database in VM is determined to have been modified since last backup.
     *
     * Note: this shouldn't be called before `lastBackupDate` has been set,
     * since that will trigger a backup on assumption of an empty backup folder.
     */
    func modified() -> Bool {
        Log.backend.debug("VirtualMachine.modified()")
        // 1. if lastBackupDate is `nil` (meaning `backupFolder` is empty)
        guard let lastBackup = self.lastBackupDate else {
            Log.backend.debug("VirtualMachine.modified() guard let lastBackup failed")
            return true
        }

        // 2. is VM running → query VetBackup for exact time
        if let exactDate = self.vmDatabaseLastModifiedDate() {
            // no grace period needed since Vetvision is always closed on backup
            if exactDate > lastBackup {
                Log.backend.debug("VirtualMachine.modified() exactDate successfully extracted")
                return true
            }
        }

        // 3. VM is not running → check disk file mod date
        if let modDate = self.diskFile.modified {
            // 10 minutes grace period since the VM is not closed on backup finish
            if modDate > lastBackup.addingTimeInterval(600) {
                // 3. VM has been used, check database modified time
                Log.backend.debug("VirtualMachine.modified() diskFile is recently modified")
                return true
            }
        }

        // VM appears untouched since last backup → return false
        Log.backend.debug("VirtualMachine.modified() VM looks untouched since last backup")
        return false
    }

    /**
     * Return the next time in the future the clock strikes `dailyBackupTime`. Either **today** or **tomorrow**.
     */
    func nextBackupDate() -> Date? {
        Log.backend.debug("VirtualMachine.nextBackupDate()")
        guard let dailyBackupTime = self.dailyBackupTime else { return nil }

        var time = DateComponents()

        time.hour = Calendar.current.component(.hour, from: dailyBackupTime)
        time.minute = Calendar.current.component(.minute, from: dailyBackupTime)
        time.second = Calendar.current.component(.second, from: dailyBackupTime)
        
        return next(time: Calendar.current.date(from: time)!)
    }

    /** The path to the VM bundle, excluding the trailing `/` */
    func path() -> String {
        String(self.url.path(percentEncoded: false).dropLast(1))
    }

    /** Returns **true** if the VM is running in VMware Fusion.  */
    func running() -> Bool {
        Log.backend.debug("VirtualMachine.running()")
        let task = Process()
        let pipe = Pipe()
        var running = false

        task.standardOutput = pipe
        task.standardError = pipe
        task.standardInput = nil
        task.executableURL = vmrun
        task.arguments = ["-T", "fusion", "list"]

        do {
            try task.run()
            let data = try pipe.fileHandleForReading.readToEnd()
            let output = String(data: data ?? Data(), encoding: .utf8)
            if output == "Total running VMs: 0" {
                return running
            }
            output?.enumerateLines { (line, _) in
                if line == self.vmxFile.path() {
                    running = true
                }
            }
        } catch {
            Log.backend.error("VirtualMachine.running() error: \(error)")
        }
        Log.backend.debug("VirtualMachine.running() -> \(running)")
        return running
    }

    /** Updates the stored exact date `Database.fdb` was modified (`.lastDatabaseModifiedDate`). Needs `running()` to return **true** to update, otherwise sets date to `nil`.  */
    func updateDatabaseLastModifiedDate() {
        guard let date = vmDatabaseLastModifiedDate(),
              date != self.lastDatabaseModifiedDate else {
            Log.backend.debug("VirtualMachine.updateDatabaseLastModifiedDate() guard failed (not running?) set date to nil")
            self.lastDatabaseModifiedDate = nil
            return
        }
        Log.backend.debug("VirtualMachine.updateDatabaseLastModifiedDate()")
        self.lastDatabaseModifiedDate = date
    }

    /**
     * Returns the precise modification date for Database.fdb in Windows. Returns nil if not available (VM not running etc).
     *
     * Executes `C:\Program Files\VetBackup\LastModifiedDate.exe` in the VM which outputs the date string into `.LastModifiedDate` in the BackupFolder.
     */
    func vmDatabaseLastModifiedDate() -> Date? {
        Log.backend.debug("VirtualMachine.databaseLastModifiedDate()")
        guard self.running() else { return nil }

        let task = Process()
        let pipe = Pipe()
        let vmrun = vmrun
        let dateFileMacUrl = self.backupFolderURL.appending(path: ".LastModifiedDate")

        task.standardOutput = pipe
        task.standardError = pipe
        task.standardInput = nil
        task.executableURL = vmrun
        task.arguments = [
            "-T", "fusion", "-vp", vmKey,
            "-gu", vmUser, "-gp", vmPasswd,
            "runProgramInGuest", "\(vmxFile.path())",
            "-interactive", vmWindowsPaths.lastModifiedDotExe,
            vmWindowsPaths.databaseDotFdb, vmWindowsPaths.lastModifiedOutput
        ]
        
        do {
            try task.run()
            let data = try pipe.fileHandleForReading.readToEnd()
            guard let output = String(data: data ?? Data(), encoding: .utf8) else { return nil }

            let dateString = try String(contentsOf: dateFileMacUrl, encoding: .utf8)
            guard dateString != "" else { return nil }
            try FileManager.default.removeItem(at: dateFileMacUrl)

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd-HHmmss"
            if let date = dateFormatter.date(from: dateString) {
                Log.backend.info("vmDatabaseLastModifiedDate() -> \(date.formatted(date: .numeric, time: .standard))")
                return date
            } else {
                return nil
            }
        } catch {
            Log.backend.error("VirtualMachine.vmDatabaseLastModifiedDate error: \(error.localizedDescription)")
            return nil
        }
    }
}

