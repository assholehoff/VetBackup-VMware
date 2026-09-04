//
//  SetupView.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-08-29.
//

import SwiftUI
import UniformTypeIdentifiers

/**
 * View to display when no valid configuration can be established. The settings will be saved into UserDefaults and the Keychain.
 */
struct SetupView: View {
    @State var backupFolder: URL = AppSettings.shared.backupFolderURL
    @State var backupFolderSet: Bool = AppSettings.shared.backupFolderURL.absoluteString != "file:///"
    @State var backupFolderString: String = AppSettings.shared.backupFolderURL.path(percentEncoded: false)
    @State var backupTime: Date = defaultDate()

    @State var runOnLogin: Bool = false

    @State var vmware: URL = AppSettings.shared.vmwareFusionAppURL
    @State var vmrun: URL = AppSettings.shared.vmrunURL
    @State var vmbundle: URL = AppSettings.shared.vmBundleURL
    @State var vmwareSet: Bool = AppSettings.shared.vmwareFusionAppURL.absoluteString != "file:///"
    @State var vmbundleSet: Bool = AppSettings.shared.vmBundleURL.absoluteString != "file:///"
    @State var vmwareString: String = AppSettings.shared.vmwareFusionAppURL.path(percentEncoded: false)
    @State var vmbundleString: String = AppSettings.shared.vmBundleURL.path(percentEncoded: false)

    @State var vmkey: String = AppSettings.shared.vmKey
    @State var vmuser: String = AppSettings.shared.vmUser
    @State var vmpasswd: String = AppSettings.shared.vmPasswd
    @State var vmkeySet: Bool = AppSettings.shared.vmKey != ""
    @State var vmuserSet: Bool = AppSettings.shared.vmUser != ""
    @State var vmpasswdSet: Bool = AppSettings.shared.vmPasswd != ""

    @State var isTargeted: Bool = false
    @State var vmIsReady: Bool = AppSettings.shared.vmIsReady
    @State var setupButtonDisabled: Bool = false

    var body: some View {
        ZStack {
            VStack {
                Text("Setup VetBackup")
                    .font(.title)
                VStack {
                    HStack(alignment: .firstTextBaseline) {
                        Image(systemName: "pc")
                        Text("VMware.app")
                        if vmwareSet {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                    HStack(alignment: .firstTextBaseline) {
                        Image(systemName: "pc")
                        Text("Virtual Machine")
                        if vmbundleSet {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                    .padding([.top, .bottom], 3)
                    HStack(alignment: .firstTextBaseline) {
                        Image(systemName: "folder")
                        Text("Backup Folder")
                        if backupFolderSet {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }
                .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                    for provider in providers {
                        provider.loadObject(ofClass: NSURL.self) { url, error in
                            guard error == nil, let anyURL = url as? URL else { return }
                            let path = anyURL.path(percentEncoded: false)
                            switch anyURL.pathExtension.lowercased() {

                            case "app":
                                DispatchQueue.main.async {
                                    self.vmware = anyURL
                                    self.vmwareSet = true
                                    self.vmwareString = anyURL.path(percentEncoded: false)
                                    let vmrunURL = anyURL.appending(path: "Contents/Public/vmrun")
                                    let vmrunPath = vmrunURL.path(percentEncoded: false)
                                    self.vmrun = vmrunURL
                                    AppSettings.shared.vmwareFusionAppURL = self.vmware
                                }

                            case "vmwarevm":
                                DispatchQueue.main.async {
                                    let path = anyURL.path(percentEncoded: false)
                                    self.vmbundle = anyURL
                                    self.vmbundleSet = true
                                    self.vmbundleString = path
                                    AppSettings.shared.vmBundleURL = self.vmbundle
                                }

                            default:
                                guard anyURL.hasDirectoryPath else { return }
                                DispatchQueue.main.async {
                                    let path = anyURL.path(percentEncoded: false)
                                    self.backupFolder = anyURL
                                    self.backupFolderSet = true
                                    self.backupFolderString = path
                                    let filename = "." + UUID().uuidString
                                    let fileURL = anyURL.appending(path: filename)
                                    let filePath = fileURL.path(percentEncoded: false)
                                    AppSettings.shared.backupFolderURL = self.backupFolder
                                }
                            }
                        }
                    }
                    return true
                }
                .padding(.top, 16)
                Form {
                    Toggle(isOn: $runOnLogin, label: { Text("Run on login") })
                        .toggleStyle(.checkbox)
                    DatePicker("Backup time", selection: $backupTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.stepperField)
                    TextField(text: $vmkey, prompt: nil, label: { Text("Key") })
                        .autocorrectionDisabled(true)
                        .onChange(of: vmkey) { _, newValue in
                            AppSettings.shared.vmKey = newValue
                            if newValue != "" { self.vmkeySet = true }
                        }
                    TextField(text: $vmuser, prompt: nil, label: { Text("User") })
                        .autocorrectionDisabled(true)
                        .onChange(of: vmuser) { _, newValue in
                            AppSettings.shared.vmUser = newValue
                            if newValue != "" { self.vmuserSet = true }
                        }
                    SecureField(text: $vmpasswd, prompt: nil, label: { Text("Password") })
                        .autocorrectionDisabled(true)
                        .onChange(of: vmpasswd) { _, newValue in
                            AppSettings.shared.vmPasswd = newValue
                            if newValue != "" { self.vmpasswdSet = true }
                        }
                }
                .frame(maxWidth: 300)
                .padding([.horizontal, .top], 16)
                Button("Proceed", systemImage: "") {
                    self.setupButtonDisabled = true
                    // FIXME: validate all settings before actually creating a Virtual Machine instance
                    let user = VMAuth(
                        user: vmuser,
                        key: vmkey,
                        passwd: vmpasswd
                    )
                    let paths = VMWindowsPaths.defaults
                    let settings = VMSettings(
                        backupFolderURL: backupFolder,
                        dailyBackupTime: backupTime
                    )
                    let vm = VirtualMachine(
                        url: vmbundle,
                        run: vmrun,
                        user: user,
                        paths: paths,
                        settings: settings
                    )
                    AppSettings.shared.setup(using: vm)
                }
                .disabled(self.setupButtonDisabled)
                .onReceive(AppSettings.shared.$vmIsReady) { newValue in
                    self.vmIsReady = newValue
                    if !newValue { self.setupButtonDisabled = false }
                }
                .padding(16)
            }
        }
        .onAppear {
            AppUIState.shared.showingSetupWindow = true
        }
        .onDisappear {
            AppUIState.shared.showingSetupWindow = false
        }
    }
}

#Preview {
//    SetupView()
}

