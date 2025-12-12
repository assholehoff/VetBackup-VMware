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

struct SettingsView: View {
    @AppStorage("BackupFolderURL") private var BackupFolderURL: URL =
        .documentsDirectory.appending(path: "VetVision", directoryHint: .isDirectory)
    @AppStorage("RunAtLogin") private var RunAtLogin: Bool = false
    @AppStorage("NotifyOnBackup") private var NotifyOnBackup: Bool = false
    
    @State var ShowBackupFolderSelector: Bool = false
    @State private var authenticated: Bool = false
    @State private var VMXPath: String = ""
    @State private var VMUser: String = ""
    @State private var VMKey: String = ""
    @State private var VMPasswd: String = ""

    @State private var LANAddress: String = ""

    var body: some View {
        TabView {
            Tab("General", systemImage: "gear") {
                Form {
                    Toggle("Run at login", isOn: $RunAtLogin)
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
                    Text("Backup folder:")
//                        .frame(maxWidth: 400, alignment: .leading)
                        .padding(.top)
                    Text(BackupFolderURL.path(percentEncoded: false))
//                        .frame(maxWidth: 400, alignment: .leading)
                    Button(action: {
                        ShowBackupFolderSelector = true
                    }, label: {
                        Text("Select folder")
                    })
                    .padding(.bottom)
                }
                .padding()
            }
            Tab("Virtual Machine", systemImage: "pc") {
                Form {
                    TextField("VMX Path", text: $VMXPath)
                        .autocorrectionDisabled(true)
                        .textContentType(.URL)
                        .onSubmit {
                            if validateVMXPath(string: VMXPath) {
                                save(data: VMXPath, account: "VMXPath")
                            }
                        }
                        .frame(maxWidth: 400, alignment: .leading)
                    SecureField("VM Key", text: $VMKey)
                        .autocorrectionDisabled(true)
                        .textContentType(.password)
                        .onSubmit {
                            save(data: VMKey, account: "VMKey")
                        }
                        .frame(maxWidth: 300, alignment: .leading)
                    TextField("VM User", text: $VMUser)
                        .autocorrectionDisabled(true)
                        .textContentType(.username)
                        .onSubmit {
                            save(data: VMUser, account: "VMUser")
                        }
                        .frame(maxWidth: 300, alignment: .leading)
                    SecureField("VM Password", text: $VMPasswd)
                        .autocorrectionDisabled(true)
                        .textContentType(.password)
                        .onSubmit {
                            save(data: VMPasswd, account: "VMPasswd")
                        }
                        .frame(maxWidth: 300, alignment: .leading)
                }
                .padding()
            }
            Tab("LAN Server", systemImage: "server.rack") {
                Form {
                    TextField("Server address", text: $LANAddress)
                    TextField("User", text: $LANAddress)
                    TextField("Directory", text: $LANAddress)
                }
                .padding()
            }
        }
        .onAppear {
            if let data = try? KeychainInterface.shared.readPassword(service: "com.ad.vetbackup", account: "VMXPath"), let path = String(data: data, encoding: .utf8) {
                VMXPath = path
            }
            if let data = try? KeychainInterface.shared.readPassword(service: "com.ad.vetbackup", account: "VMUser"), let user = String(data: data, encoding: .utf8) {
                VMUser = user
            }
            if let data = try? KeychainInterface.shared.readPassword(service: "com.ad.vetbackup", account: "VMKey"), let key = String(data: data, encoding: .utf8) {
                VMKey = key
            }
            if let data = try? KeychainInterface.shared.readPassword(service: "com.ad.vetbackup", account: "VMPasswd"), let passwd = String(data: data, encoding: .utf8) {
                VMPasswd = passwd
            }
            if allSet() {
                // TODO verify these work with vmrun and prompt if not
                authenticated = true
            }
        }
        .padding()
        .fileImporter(isPresented: $ShowBackupFolderSelector,
                      allowedContentTypes: [UTType.folder],
                      allowsMultipleSelection: false,
                      onCompletion: {
            (Result) in
            do {
                BackupFolderURL = try Result.get()[0]
                ShowBackupFolderSelector = false
            } catch {
                print("error selecting BackupFolder: \(Result)")
            }
        })
    }

    private func allSet() -> Bool {
        if VMXPath != "" && VMUser != "" && VMKey != "" && VMPasswd != "" {
            return true
        }
        return false
    }
    private func validateVMXPath(string: String) -> Bool {
        if FileManager.default.fileExists(atPath: string) {
            if (FilePath(string).lastComponent!.string.contains(/.*\.vmx$/)) {
                return true
            }
        }
        return false
    }
    private func save(data: String, account: String) {
        if data != "" {
            do {
                try KeychainInterface.shared.update(password: data.data(using: .utf8)!, service: "com.ad.vetbackup", account: account)
            } catch KeychainInterface.KeychainError.itemNotFound {
                try? KeychainInterface.shared.save(password: data.data(using: .utf8)!, service: "com.ad.vetbackup", account: account)
            } catch {
                print("error saving in keychain: \(error)")
            }
            if allSet() {
                authenticated = true
            }
        } else {
            authenticated = false
        }
    }
}

#Preview {
    SettingsView()
}
