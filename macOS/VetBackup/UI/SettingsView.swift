//
//  SettingsView.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2025-12-05.
//

import SwiftUI
import System
import UniformTypeIdentifiers
import UserNotifications

import LaunchAtLogin

struct SettingsView: View {
    @AppStorage("RunAtLogin") private var RunAtLogin: Bool = false
    @AppStorage("NotifyOnBackup") private var NotifyOnBackup: Bool = false
    @AppStorage("Paused") private var Paused: Bool = false
    
    @EnvironmentObject private var vmp: VMProvider
    
    @State var ShowBackupFolderSelector: Bool = false
    @State private var bfIsConfigured: Bool = false
    @State private var vmIsConfigured: Bool = false
    @State private var VMXPath: String = ""
    @State private var VMUser: String = ""
    @State private var VMKey: String = ""
    @State private var VMPasswd: String = ""
    
    @State private var LANAddress: String = ""
    
    @State var selectedTab = 0
    
    var body: some View {
        if let vm = vmp.vm {
            TabView(selection: $selectedTab) {
                Tab("General", systemImage: "gear", value: 0) {
                    Form {
                        LaunchAtLogin.Toggle(String(localized: .launchAtLogin))
                        Toggle("Notify on backup", isOn: $NotifyOnBackup)
                            .onChange(of: NotifyOnBackup, {
                                if NotifyOnBackup {
                                    // check for permission, if not, ask
                                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                                        if success {
                                            print(success)
                                        } else if let error {
                                            print(error.localizedDescription)
                                            NotifyOnBackup = false
                                        }
                                    }
                                }
                            })
                        DatePicker("Backup time", selection: Binding(
                            get: { vm.BackupTime },
                            set: { vm.SetBackupTime(time: $0) }),
                            displayedComponents: .hourAndMinute
                        )
                            .padding(.top)
                            .onAppear {
                                print("DatePicker.onAppear()")
                                print("BackupTime: \(vm.BackupTime)")
                                print("BackupTime: \(vm.BackupTime.formatted())")
                            }
                            .onSubmit {
                                // Change BackupTime
                                // Calendar.current.dateComponents([.hour, .minute], from: BackupTime)
                                print("DatePicker.onSubmit()")
                            }
                        Text("Backup folder")
    //                        .frame(maxWidth: 400, alignment: .leading)
                            .padding(.top)
                        Text(prettyFolder(url: vm.BackupFolder))
    //                        .frame(maxWidth: 400, alignment: .leading)
                        Button(action: {
                            ShowBackupFolderSelector = true
                        }, label: {
                            Text("Select folder")
                        })
                        .padding(.bottom)
                    }
                    .onAppear() {
                        if vm.BackupFolder.isFileURL {
                            bfIsConfigured = false
                            ShowBackupFolderSelector = true
                        }
                    }
                    .padding()
                }
                Tab("Virtual Machine", systemImage: "pc", value: 1) {
                    Form {
                        TextField("VMX Path", text: $VMXPath)
                            .autocorrectionDisabled(true)
                            .textContentType(.URL)
                            .onChange(of: VMXPath, {
                                if validateVMXPath(string: VMXPath) {
                                    if save(data: VMXPath, account: "VMXPath") {
                                        //
                                        // TODO: verify this
                                        //
                                        vm.SetVMXFile(url: URL(fileURLWithPath: VMXPath))
                                    }
                                }
                            })
                            .frame(maxWidth: 400, alignment: .leading)
                        TextField("VM Key", text: $VMKey)
                            .autocorrectionDisabled(true)
                            .textContentType(.username)
                            .onChange(of: VMKey, {
                                if save(data: VMKey, account: "VMKey") {
                                    vm.VMKey = VMKey
                                }
                            })
                            .frame(maxWidth: 300, alignment: .leading)
                        TextField("VM User", text: $VMUser)
                            .autocorrectionDisabled(true)
                            .textContentType(.username)
                            .onChange(of: VMUser, {
                                if save(data: VMUser, account: "VMUser") {
                                    vm.VMUser = VMUser
                                }
                            })
                            .frame(maxWidth: 300, alignment: .leading)
                        SecureField("VM Password", text: $VMPasswd)
                            .autocorrectionDisabled(true)
                            .textContentType(.password)
                            .onChange(of: VMPasswd, {
                                if save(data: VMPasswd, account: "VMPasswd") {
                                    vm.VMPasswd = VMPasswd
                                }
                            })
                            .frame(maxWidth: 300, alignment: .leading)
                    }
                    .padding()
                }
                Tab("LAN Server", systemImage: "server.rack", value: 2) {
                    Form {
                        TextField("Server address", text: $LANAddress)
                        TextField("User", text: $LANAddress)
                        TextField("Directory", text: $LANAddress)
                    }
                    .padding()
                }
            }
            .padding()
            .fileImporter(isPresented: $ShowBackupFolderSelector,
                          allowedContentTypes: [UTType.folder],
                          allowsMultipleSelection: false,
                          onCompletion: { (Result) in
                do {
                    vm.BackupFolder = try Result.get()[0]
                    if vm.BackupFolder.isFileURL {
                        ShowBackupFolderSelector = false
                        bfIsConfigured = true
                    }
                } catch {
                    print("error selecting BackupFolder: \(Result)")
                }
            })
            .onAppear() {
                VMXPath = loadKey("VMXPath")
                VMKey = loadKey("VMKey")
                VMUser = loadKey("VMUser")
                VMPasswd = loadKey("VMPasswd")
            }
        } else {
            LoadingView()
        }
    }

    private func allSet() -> Bool {
        if VMXPath != "" && VMUser != "" && VMKey != "" && VMPasswd != "" {
            return true
        }
        return false
    }
    private func prettyFolder(url: URL) -> String {
        if url.path.count > 1 {
            let folder = url.path(percentEncoded: false)
            if folder.hasSuffix("/") {
                return String(folder.dropLast(1))
            } else {
                return folder
            }
        }
        return url.path(percentEncoded: false)
    }
    private func validateVMXPath(string: String) -> Bool {
        if FileManager.default.fileExists(atPath: string) {
            if (FilePath(string).lastComponent!.string.contains(/.*\.vmx$/)) {
                return true
            }
        }
        return false
    }
    private func save(data: String, account: String) -> Bool {
        if data != "" {
            do {
                try KeychainInterface.shared.update(password: data.data(using: .utf8)!, service: "com.ad.vetbackup", account: account)
            } catch KeychainInterface.KeychainError.itemNotFound {
                try? KeychainInterface.shared.save(password: data.data(using: .utf8)!, service: "com.ad.vetbackup", account: account)
            } catch {
                print("error saving in keychain: \(error)")
                return false
            }
            if allSet() {
                vmIsConfigured = true
            }
        } else {
            vmIsConfigured = false
        }
        return true
    }
    private func loadKey(_ account: String) -> String {
        if let data = try? KeychainInterface.shared.readPassword(service: "com.ad.vetbackup", account: account),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return ""
    }
}

#Preview {
    SettingsView()
}
