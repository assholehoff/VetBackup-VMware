//
//  VM.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2025-12-04.
//

import Combine
import Foundation
import RegexBuilder
import UserNotifications

enum VirtualMachineError: Error {
    case vmNotFound
    case vmxFileNotFound
    case vmDiskFileNotFound
    case invalidKey
    case invalidUsername
    case invalidPassword
    case vmOffline
    case vmNotResponding
}

@MainActor
public class VirtualMachine: ObservableObject {
    var VMXFile: VMXFile
    var VMDisk: File
    
    @Published var BackupFolder: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("VetVision", isDirectory: true) // TODO: set this and update String in @AppStorage
    @Published var BackupOngoing: Bool = false
    @Published var BackupTime: Date = Date.distantPast
    @Published var LastBackupDate: Date = Date.distantPast
    
    @Published var VMKey: String
    @Published var VMUser: String
    @Published var VMPasswd: String
    
    let VMRunPath: String = "/Applications/VMware Fusion.app/Contents/Public/vmrun"
    
    let WinCMDPath: String = "C:\\Windows\\System32\\cmd.exe"
    let WinPwShPath: String = "C:\\Program Files\\PowerShell\\7\\pwsh.exe"
    var WinProgram: String = "C:\\Program Files\\VetBackup\\VetBackup.exe"
    var WinDatabasePath: String = "C:\\VetVision\\VETDB\\Database.fdb"
    
    convenience init(vmx: URL) {
        self.init(vmx: vmx, VMKey: "", VMUser: "", VMPasswd: "")
    }
    
    init(vmx: URL, VMKey: String, VMUser: String, VMPasswd: String) {
        self.VMXFile = VetBackup.VMXFile(url: vmx)
        self.VMDisk = File(url: VMXFile.DiskFileURL())
        self.VMKey = VMKey
        self.VMUser = VMUser
        self.VMPasswd = VMPasswd
    }
    
    func SetVMXFile(url: URL) {
        self.VMXFile = VetBackup.VMXFile(url: url)
        self.VMDisk = File(url: VMXFile.DiskFileURL())
    }
    
    func SetBackupFolder(url: URL) {
        self.BackupFolder = url
        self.LastBackupDateFromFolder(url: self.BackupFolder)
    }
    
    func LastBackupDateFromFolder(url: URL) {
        let files = BackupFilesIn(folder: url)
        if files.count > 0 {
            self.LastBackupDate = files.first?.date ?? Date.distantPast
        }
        print("set lastBackupDate to \(self.LastBackupDate.formatted(date: .abbreviated, time: .shortened))")
    }
    
    func Authenticated() -> Bool {
        if VMKey != "" && VMUser != "" && VMPasswd != "" {
            return true
        }
        return false
    }
    
    func Backup() -> Bool {
        var result = false
        self.BackupOngoing = true
        DispatchQueue.main.async(execute: { [self] in
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
            UNUserNotificationCenter.current().add(request)

            print("Backup()")
            let offString: String = "Error: The virtual machine is not powered on: \(VMXFile.Path())\n"
            let task = Process()
            let pipe = Pipe()
            
            task.standardOutput = pipe
            task.standardError = pipe
            task.standardInput = nil
            task.executableURL = URL(fileURLWithPath: VMRunPath)
            task.arguments = ["-T", "fusion", "-vp", VMKey, "-gu", VMUser, "-gp", VMPasswd, "runProgramInGuest", "\(VMXFile.Path())", "-activeWindow", "-interactive", WinProgram, WinDatabasePath]
            
            do {
                try task.run()
                let data = try pipe.fileHandleForReading.readToEnd()
                let output = String(data: data ?? Data(), encoding: .utf8)
                if output != "" && output != offString {
                    print(output!)
                }
                if output == offString {
                    self.BackupOngoing = false

                    UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [uuid])
                    UNUserNotificationCenter.current().add(errorRequest)

                    result = false
                } else {
                    result = true
                }
            } catch {
                print("error: \(error)")
                self.BackupOngoing = false
                result = false

                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [uuid])
                UNUserNotificationCenter.current().add(errorRequest)
            }

            if result {
                let successContent = UNMutableNotificationContent()
                successContent.title = String(localized: "Backup completed")
                successContent.subtitle = String(localized: "Backup completed on ") + Date().formatted(date: .abbreviated, time: .shortened)
                let successTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
                let successRequest = UNNotificationRequest(identifier: UUID().uuidString, content: successContent, trigger: successTrigger)
                UNUserNotificationCenter.current().add(successRequest)
            }
            
            self.BackupOngoing = false
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [uuid])
        })
        return result
    }
    
    func BackupIfNeeded() async {
        if self.Modified() {
            print("Backup is needed")
            _ = self.Backup()
        } else {
            print("Backup is not needed, skipping")
        }
    }
    
    func Modified() -> Bool {
        //
        // TODO: Windows component checks database file modification time and exports to a file
        //       this side then compares to LastBackupDate and returns true or false
        //
        if self.LastBackupDate == Date.distantPast {
            // Last backup time is uncertain or never
            print("lastBackupDate is nil, Modified() returning true")
            return true
        }
        
        if let mod = self.VMDisk.ModifiedDate() {
            if mod > self.LastBackupDate {
                // VM has been used since last backup
                print("\(mod) > \(self.LastBackupDate), Modified() returning true")
                return true
            }
        }
    
        // VM appears untouched since last backup
        print("Modified() returning false")
        return false
    }
    
    func SetBackupTime(time: Date) {
        self.BackupTime = time
        print("VirtualMachine.SetBackupTime(time: \(time))")
    }
    
    func NextBackupDate() -> Date {
        if self.BackupTime == Date.distantPast {
            print("NextBackupDate(): VirtualMachine.BackupTime is .distantPast: \(self.BackupTime)")
            print("** returning Date() **")
            // this *really* shouldn't happen
            return Date()
        }
        
        let btime = self.BackupTime
        var time = DateComponents()
        
        time.hour = Calendar.current.component(.hour, from: btime)
        time.minute = Calendar.current.component(.minute, from: btime)
        time.second = Calendar.current.component(.second, from: btime)
        
        let date = Next(time: Calendar.current.date(from: time)!)
        
        return date
    }
    
    func SetLastBackupDate(date: Date) {
        self.LastBackupDate = date
    }
    
    func Path() -> String {
        String(VMXFile.id.deletingLastPathComponent().path(percentEncoded: false).dropLast(1))
    }
    
    func Running() -> Bool {
        let task = Process()
        let pipe = Pipe()
        var running = false
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.standardInput = nil
        task.executableURL = URL(fileURLWithPath: VMRunPath)
        task.arguments = ["-T", "fusion", "list"]
        
        do {
            try task.run()
            let data = try pipe.fileHandleForReading.readToEnd()
            let output = String(data: data ?? Data(), encoding: .utf8)
            if output == "Total running VMs: 0" {
                return running
            }
            output?.enumerateLines { (line, _) in
                if line == self.VMXFile.Path() {
                    running = true
                }
            }
        } catch {
            print("error: \(error)")
        }
        return running
    }
    
    func LoggedIn(user: String) -> Bool {
        return vmrunUsers(user: user)
    }
    
    private func vmrunUsers(user: String) -> Bool {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.standardInput = nil
        task.executableURL = URL(fileURLWithPath: VMRunPath)
        task.arguments = ["-T", "fusion", "-vp", VMKey, "-gu", VMUser, "-gp", VMPasswd, "runProgramInGuest", "\(VMXFile.Path())", WinCMDPath, "query user"]
        
        do {
            try task.run()
            let data = try pipe.fileHandleForReading.readToEnd()
            let output = String(data: data ?? Data(), encoding: .utf8)
            if output != "" {
                print(output!)
            }
            let useregex = Regex {
                /^pid=[0-9]+\, owner=.*\\/
                user
                /\, cmd=vmtoolsd\.exe$/
            }
            if !(output?.contains(useregex) ?? false) {
                print("output does not contain regex")
                print("return false")
                return false
            }
        } catch {
            print("error: \(error)")
            return false
        }
        
        return true
    }
    
    private func vmrunQueryUserString() -> String {
        let QueryUserArguments = "query user"
        
        return "\(VMRunPath) -T fusion -vp '\(self.VMKey)' -gu '\(self.VMUser)' -gp '\(self.VMPasswd)' runProgramInGuest '\(VMXFile.Path())' '\(WinCMDPath)' '\(QueryUserArguments)'"
    }
    
    private func vmrunString() -> String {
        return "\(VMRunPath) -T fusion -vp '\(self.VMKey)' -gu '\(self.VMUser)' -gp '\(self.VMPasswd)' runProgramInGuest '\(VMXFile.Path())' '\(WinProgram)' '\(WinDatabasePath)'"
    }
}
