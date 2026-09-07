//
//  General.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-08-30.
//

import LaunchAtLogin
import SwiftUI
import UniformTypeIdentifiers

struct GeneralTabView: View {
    @State var backupFolderURL: URL = AppSettings.shared.backupFolderURL
    @State var dailyBackupEnabled: Bool = AppSettings.shared.dailyBackupEnabled
    @State var dailyBackupTime: Date = AppSettings.shared.dailyBackupTime

    @State var vmwareFusionAppURL: URL = AppSettings.shared.vmwareFusionAppURL

    @State var isTargeted: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            Form {
                Section {
                    LaunchAtLogin.Toggle(String(localized: "Launch at login"))
                    Toggle(isOn: $dailyBackupEnabled, label: {
                        Text("Daily backup")
                    })
                    .onChange(of: dailyBackupEnabled, { oldValue, newValue in
                        if AppSettings.shared.dailyBackupEnabled != newValue {
                            AppSettings.shared.dailyBackupEnabled = newValue
                        }
                    })
                    .toggleStyle(.checkbox)
                    DatePicker(
                        "Backup time", selection: $dailyBackupTime,
                        displayedComponents: .hourAndMinute
                    )
                    .onChange(of: dailyBackupTime, { oldValue, newValue in
                        if AppSettings.shared.dailyBackupTime != newValue {
                            AppSettings.shared.dailyBackupTime = newValue
                        }
                    })
                    .datePickerStyle(.stepperField)
                    .padding(.top, 4)
                    .padding(.bottom, 1)
                    LabeledContent(content: {
                        Text((backupFolderURL.path(percentEncoded: false) as NSString).abbreviatingWithTildeInPath)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: 180)
                            .multilineTextAlignment(.leading)
                    }, label: {
                        Text("Folder")
                    })
                    .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                        guard !providers.isEmpty, providers.count == 1 else { return false }
                        for provider in providers {
                            provider.loadObject(ofClass: NSURL.self) { nsurl, error in
                                guard error == nil, let url = nsurl as? URL, url.hasDirectoryPath else { return }
                                DispatchQueue.main.async { AppSettings.shared.backupFolderURL = url }
                            }
                        }
                        return true
                    }
                }
                Section {
                    LabeledContent(content: {
                        Text(vmwareFusionAppURL.path(percentEncoded: false).dropLast(1))
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }, label: {
                        Text("Path")
                    })
                    .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                        guard !providers.isEmpty, providers.count == 1 else { return false }
                        for provider in providers {
                            provider.loadObject(ofClass: NSURL.self) { nsurl, error in
                                guard error == nil, let url = nsurl as? URL, url.pathExtension == "app" else { return }
                                let vmrunURL = url.appending(path: "Contents/Public/vmrun")
                                guard FileManager.default.fileExists(atPath: vmrunURL.path(percentEncoded: false)) else { return }
                                DispatchQueue.main.async { AppSettings.shared.vmwareFusionAppURL = url }
                            }
                        }
                        return true
                    }
                }
                .padding(.vertical)
            }
        }
        .onReceive(AppSettings.shared.$backupFolderURL) { newValue in
            backupFolderURL = newValue
        }
        .onReceive(AppSettings.shared.$dailyBackupEnabled) { newValue in
            dailyBackupEnabled = newValue
        }
        .onReceive(AppSettings.shared.$dailyBackupTime) { newValue in
            dailyBackupTime = newValue
        }
        .onReceive(AppSettings.shared.$vmwareFusionAppURL) { newValue in
            vmwareFusionAppURL = newValue
        }
    }
}
