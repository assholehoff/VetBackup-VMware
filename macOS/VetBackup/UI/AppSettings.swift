//
//  AppSettings.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-08-29.
//

import AppKit
import Combine
import Foundation
import os

/**
 * Class for use in the SettingsView. Validates new settings and updates VirtualMachine accordingly.
 */
final class AppSettings: ObservableObject {
    // User selected Backup Folder where all the .zip archives end up
    @Published var backupFolderURL: URL { didSet {
        Log.app.debug("AppSettings.backupFolderURL.didSet()")
        UserDefaults.standard.set(self.backupFolderURL, forKey: "BackupFolder URL")
        Task { @MainActor in
            await self.bf.setup(url: self.backupFolderURL)
        }
        guard self.vm != nil else { return }
        if self.vm?.backupFolderURL != self.backupFolderURL {
            self.vm?.backupFolderURL = self.backupFolderURL
        }
    }}

    @Published var lastBackupDate: Date = .distantPast
    @Published var nextBackupDate: Date = .distantPast

    @Published var dailyBackupTime: Date { didSet {
        Log.app.debug("AppSettings.dailyBackupTime.didSet()")
        UserDefaults.standard.set(self.dailyBackupTime, forKey: "DailyBackupTime")
        guard self.vm != nil else { return }
        if self.vm?.dailyBackupTime != self.dailyBackupTime {
            self.vm?.dailyBackupTime = self.dailyBackupTime
        }
        if self.dailyBackupEnabled {
            self.start()
        } else {
            self.stop()
        }
    }}

    @Published var dailyBackupEnabled: Bool { didSet {
        Log.app.debug("AppSettings.dailyBackupEnabled.didSet()")
        UserDefaults.standard.set(self.dailyBackupEnabled, forKey: "DailyBackupEnabled")
        guard self.vm != nil else { return }
        if self.dailyBackupEnabled {
            self.start()
        } else {
            self.stop()
        }
    }}

    // VMware Fusion.app -- contains the `vmrun` command
    @Published var vmwareFusionAppURL: URL { didSet {
        Log.app.debug("AppSettings.vmwareFusionAppURL.didSet()")
        UserDefaults.standard.set(self.vmwareFusionAppURL, forKey: "VMwareFusion.app URL")
        self.vmrunURL = createVmrunURL(fromApp: self.vmwareFusionAppURL)
        guard self.vm != nil else { return }
        self.vm?.vmrun = self.vmrunURL
    }}

    // VirtualMachine.vmwarevm bundle -- contains the vmx file and the disk file
    @Published var vmBundleURL: URL { didSet {
        Log.app.debug("AppSettings.vmBundleURL.didSet()")
        UserDefaults.standard.set(self.vmBundleURL, forKey: "VirtualMachine URL")
        guard self.vm != nil else { return }
        if self.vm?.url != self.vmBundleURL {
            self.vm?.url = self.vmBundleURL
        }
    }}

    // User's username for the VM -- needed to use `vmrun`
    @Published var vmUser: String = "" { didSet {
        Log.app.debug("AppSettings.vmUser.didSet()")
        UserDefaults.standard.set(self.vmUser, forKey: "VM: user")
        guard self.vm != nil else { return }
        if self.vm?.vmUser != self.vmUser {
            self.vm?.vmUser = self.vmUser
        }
    }}

    // The encryption key string for the VM -- needed to use `vmrun`
    @Published var vmKey: String = "" { didSet {
        Log.app.debug("AppSettings.vmKey.didSet()")
        UserDefaults.standard.set(self.vmKey, forKey: "VM: key")
        guard self.vm != nil else { return }
        if self.vm?.vmKey != self.vmKey {
            self.vm?.vmKey = self.vmKey
        }
    }}

    // User's password for the VM -- needed to use `vmrun`
    @Published var vmPasswd: String = "" { didSet {
        Log.app.debug("AppSettings.vmPasswd.didSet()")
        Task { @MainActor in
            await updateKeychain(password: self.vmPasswd, account: "VirtualMachine password")
        }
        guard self.vm != nil else { return }
        if self.vm?.vmPasswd != self.vmPasswd {
            self.vm?.vmPasswd = self.vmPasswd
        }
    }}

    var vmrunURL: URL

    var bf: BFProvider = BFProvider()

    var vm: VirtualMachine?
    private var schedulerTask: Task<Void, Never>?
    private var subscriptions: Set<AnyCancellable> = []

    static let shared: AppSettings = AppSettings()

    @Published private(set) var backupOngoing: Bool = false
    @Published private(set) var canBackup: Bool = true
    @Published private(set) var canQuit: Bool = true
    @Published private(set) var vmIsReady: Bool = false

    init() {
        Log.app.debug("AppSettings.init()")
        // `BackupFolder URL` RW access
        var backupFolderURL = URL(string: "file:///")!
        if let potentialURL = UserDefaults.standard.url(forKey: "BackupFolder URL") {
            Log.app.debug("AppSettings.init() successfully resolved \"BackupFolder URL\" from UserDefaults!")
            backupFolderURL = potentialURL
        }
        self.backupFolderURL = backupFolderURL
        
        // `VMwareFusion.app URL` RO access
        var vmwareFusionURL = URL(string: "file:///")!
        if let potentialURL = UserDefaults.standard.url(forKey: "VMwareFusion.app URL") {
            Log.app.debug("AppSettings.init() successfully resolved \"VMwareFusion.app URL\" from UserDefaults!")
            vmwareFusionURL = potentialURL
        }
        self.vmwareFusionAppURL = vmwareFusionURL
        self.vmrunURL = createVmrunURL(fromApp: vmwareFusionURL)
        
        // `VirtualMachine URL` RO access
        var virtualMachineURL = URL(string: "file:///")!
        if let potentialURL = UserDefaults.standard.url(forKey: "VirtualMachine URL") {
            Log.app.debug("AppSettings.init() successfully resolved \"VirtualMachine URL\" from UserDefaults!")
            virtualMachineURL = potentialURL
        }
        self.vmBundleURL = virtualMachineURL
        
        self.dailyBackupTime = UserDefaults.standard.object(forKey: "DailyBackupTime") as? Date ?? defaultDate()
        self.dailyBackupEnabled = UserDefaults.standard.bool(forKey: "DailyBackupEnabled")
        
        if let user = UserDefaults.standard.string(forKey: "VM: user") {
            Log.app.debug("AppSettings.init() successfully resolved \"VM: user\" from UserDefaults!")
            self.vmUser = user
        }
        
        if let key = UserDefaults.standard.string(forKey: "VM: key") {
            Log.app.debug("AppSettings.init() successfully resolved \"VM: key\" from UserDefaults!")
            self.vmKey = key
        }
        
        if let password = loadKeychainValue("VirtualMachine password") {
            Log.app.debug("AppSettings.init() successfully resolved \"VM: password\" from UserDefaults!")
            self.vmPasswd = password
        }

        if checkFields() {
            Log.app.debug("AppSettings.init() checkFields passed, assembling VM instance")
            setup(using: VirtualMachine(
                url: self.vmBundleURL,
                run: self.vmrunURL,
                user: VMAuth(
                    user: self.vmUser,
                    key: self.vmKey,
                    passwd: self.vmPasswd
                ),
                paths: VMWindowsPaths.defaults,
                settings: VMSettings(
                    backupFolderURL: self.backupFolderURL,
                    dailyBackupTime: self.dailyBackupTime
                )
            ))
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(self.wakeuproutine(_:)),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        if self.dailyBackupEnabled, self.vm != nil {
            Log.app.debug("AppSettings.init() starting daily backup timer")
            self.start()
        }
    }

    @objc func wakeuproutine(_ notification: NSNotification) {
        Log.app.debug("AppSettings.wakeuproutine() received NSWorkspace.didWakeNotification")
        guard self.dailyBackupEnabled else { return }
        if self.nextBackupDate < .now {
            Log.app.info("AppSettings.wakeuproutine() backup time passed while asleep! initiate backup routine...")
            Task { await self.vm?.backupIfNeeded() }
        }
        self.start()
    }

    func setup(using vm: VirtualMachine) {
        Log.app.debug("AppSettings.setup(using: VirtualMachine)")
        self.backupFolderURL = vm.backupFolderURL
        self.dailyBackupTime = vm.dailyBackupTime ?? defaultDate()
        self.vmBundleURL = vm.url
        self.vmUser = vm.vmUser
        self.vmKey = vm.vmKey
        self.vmPasswd = vm.vmPasswd

        self.vm = vm

        self.nextBackupDate = vm.nextBackupDate() ?? .distantPast

        self.vm?.$lastBackupDate
            .sink { value in
                Log.app.debug("AppSettings.vm?.$lastBackupDate.sink()")
                guard let value else { return }
                self.lastBackupDate = value
            }
            .store(in: &self.subscriptions)

        self.vm?.$backupOngoing
            .sink { value in
                Log.app.debug("AppSettings.vm?.$backupOngoing.sink()")
                self.backupOngoing = value
                if self.backupOngoing {
                    self.canBackup = false
                    self.canQuit = true
                } else {
                    self.canBackup = true
                    self.canQuit = true
                }
            }
            .store(in: &self.subscriptions)

        self.vmIsReady = true

        self.bf.$folder
            .compactMap { $0 }      // ignore `nil` folders
            .flatMap { $0.$files }  // for each new folder, observe its $files
            .sink { files in
                Log.app.debug("AppSettings.bf.$folder.sink()")
                if let date = files.first?.date {
                    self.lastBackupDate = date
                }
            }
            .store(in: &self.subscriptions)
    }

    func start() {
        Log.app.debug("AppSettings.start()")
        self.nextBackupDate = vm?.nextBackupDate() ?? .distantPast
        schedulerTask?.cancel()
        if let _ = vm?.dailyBackupTime {
            schedulerTask = Task { [weak self] in
                while !Task.isCancelled {
                    Log.app.info("AppSettings.schedulerTask fire!")
                    guard let self else { return }
                    if let next = vm?.nextBackupDate() {
                        try? await Task.sleep(until: .now.advanced(by: .seconds(next.timeIntervalSinceNow)), clock: .continuous)
                        if Task.isCancelled { return }
                        await self.vm?.backupIfNeeded()
                    }
                }
            }
        }
    }

    func stop() {
        Log.app.debug("AppSettings.stop()")
        self.nextBackupDate = .distantPast
        schedulerTask?.cancel()
        schedulerTask = nil
    }

    private func checkFields() -> Bool {
        Log.app.debug("AppSettings.checkFields()")
        return self.vmUser != "" && self.vmKey != "" && self.vmPasswd != ""
    }

    private func loadKeychainValue(_ account: String) -> String? {
        Log.app.debug("AppSettings.loadKeychainValue()")
        do {
            let data = try KeychainInterface.shared.readPassword(service: "com.ad.vetbackup", account: account)
            let value = String(data: data, encoding: .utf8)
            return value
        } catch {
            print("\(timeStamp()) AppSettings.updateKeychain: failed read from Keychain!")
            print("\(timeStamp()) KeychainInterface.shared.readPassword threw exception: \(error.localizedDescription)")
        }
        return nil
    }

    private func updateKeychain(password: String, account: String) async {
        Log.app.debug("AppSettings.updateKeychainPassword(password:account:)")
        guard password != "" else { return }
        do {
            try KeychainInterface.shared.update(password: password.data(using: .utf8)!, service: "com.ad.vetbackup", account: account)
        } catch KeychainInterface.KeychainError.itemNotFound {
            do {
                try KeychainInterface.shared.save(password: password.data(using: .utf8)!, service: "com.ad.vetbackup", account: account)
            } catch {
                Log.app.debug("AppSettings.updateKeychain(password:account:) failed to update Keychain")
                Log.app.error("AppSettings.updateKeychain(password:account:) error: \(error)")
            }
        } catch {
            Log.app.debug("AppSettings.updateKeychain(password:account:) failed to update Keychain")
            Log.app.error("AppSettings.updateKeychain(password:account:) error: \(error)")
        }
    }
}
