//
//  DiagnosticsView.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-08-30.
//

import SwiftUI

struct DiagnosticsView: View {
    @State var vmwareSet: Bool = AppSettings.shared.vmwareFusionAppURL.absoluteString != "file:///"
    @State var vmbundleSet: Bool = AppSettings.shared.vmBundleURL.absoluteString != "file:///"
    @State var backupFolderSet: Bool = AppSettings.shared.backupFolderURL.absoluteString != "file:///"

    @State var vmIsReady: Bool = AppSettings.shared.vmIsReady

    @State var vmwareString: String = AppSettings.shared.vmwareFusionAppURL.path(percentEncoded: false)
    @State var vmbundleString: String = AppSettings.shared.vmBundleURL.path(percentEncoded: false)
    @State var backupFolderString: String = AppSettings.shared.backupFolderURL.path(percentEncoded: false)
    @State var vmUserString: String = AppSettings.shared.vmUser
    @State var vmKeyString: String = AppSettings.shared.vmKey
    @State var vmPasswdString: String = AppSettings.shared.vmPasswd

    @State var vmDatabaseFdbModifiedString: String = ""
    @State var vmLastBackupAttemptString: String = ""
    @State var vmRunningString: String = ""
    @State var vmLastDateString: String = ""
    @State var vmModifiedString: String = ""
    @State var vmNextDateString: String = ""
    @State var vmButtonDisabled: Bool = AppSettings.shared.vm == nil

    var body: some View {
        ZStack {
            HStack(spacing: 24) {
                Spacer()
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            VStack(alignment: .leading) {
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
                                Text(backupFolderString).foregroundStyle(.secondary).font(.footnote)
                            }
                            .padding(.bottom, 8)
                            VStack(alignment: .leading) {
                                HStack(alignment: .firstTextBaseline) {
                                    Image(systemName: "pc")
                                    Text("VMware Fusion.app")
                                    if vmwareSet {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    } else {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.red)
                                    }
                                }
                                Text(vmwareString).foregroundStyle(.secondary).font(.footnote)
                            }
                            VStack(alignment: .leading) {
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
                                    if vmIsReady {
                                        Image(systemName: "hand.thumbsup.fill")
                                            .foregroundStyle(.yellow)
                                    } else {
                                        Image(systemName: "hand.thumbsdown.fill")
                                            .foregroundStyle(.orange)
                                    }
                                }
                                Text(vmbundleString).foregroundStyle(.secondary).font(.footnote)
                            }
                            Form {
                                LabeledContent(content: {
                                    Text(vmKeyString)
                                }, label: {
                                    HStack(alignment: .firstTextBaseline) {
                                        Image(systemName: "key.fill")
                                    }
                                }).padding(1)
                                LabeledContent(content: {
                                    Text(vmUserString)
                                }, label: {
                                    HStack(alignment: .firstTextBaseline) {
                                        Image(systemName: "person.fill")
                                    }
                                }).padding(1)
                                LabeledContent(content: {
                                    Text(vmPasswdString)
                                }, label: {
                                    HStack(alignment: .firstTextBaseline) {
                                        Image(systemName: "lock.fill")
                                    }
                                }).padding(1)
                            }
                            .padding(.top, 8)
                        }
                    }
                }
                VStack(spacing: 12) {
                    VStack {
                        Text("Last backup attempt")
                            .font(.footnote)
                        Text(vmLastBackupAttemptString)
                            .bold()
                    }
                    VStack {
                        Button("Running", systemImage: "figure.run") {
                            if let running = AppSettings.shared.vm?.running() {
                                if running {
                                    vmRunningString = "true"
                                } else {
                                    vmRunningString = "false"
                                }
                            }
                        }
                        .disabled(vmButtonDisabled)
                        if vmRunningString != "" {
                            Text(vmRunningString)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    VStack {
                        Button("Modified", systemImage: "calendar") {
                            if let modified = AppSettings.shared.vm?.modified() {
                                if modified {
                                    vmModifiedString = "true"
                                } else {
                                    vmModifiedString = "false"
                                }
                            }
                        }
                        .disabled(vmButtonDisabled)
                        if vmModifiedString != "" {
                            Text(vmModifiedString)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    VStack {
                        Button("Database.fdb", systemImage: "calendar") {
                            if let date = AppSettings.shared.vm?.vmDatabaseLastModifiedDate() {
                                vmDatabaseFdbModifiedString = date.formatted()
                            } else {
                                vmDatabaseFdbModifiedString = "nil"
                            }
                        }
                        .disabled(vmButtonDisabled)
                        if vmDatabaseFdbModifiedString != "" {
                            Text(vmDatabaseFdbModifiedString)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    VStack {
                        Button("Last Date", systemImage: "calendar") {
                            if let date = AppSettings.shared.vm?.lastBackupDate {
                                vmLastDateString = date.formatted()
                            } else {
                                vmLastDateString = "nil"
                            }
                        }
                        .disabled(vmButtonDisabled)
                        if vmLastDateString != "" {
                            Text(vmLastDateString)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    VStack {
                        Button("Next Date", systemImage: "calendar") {
                            if let date = AppSettings.shared.vm?.nextBackupDate() {
                                vmNextDateString = date.formatted()
                            } else {
                                vmNextDateString = "nil"
                            }
                        }
                        .disabled(vmButtonDisabled)
                        if vmNextDateString != "" {
                            Text(vmNextDateString)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
            }
        }
        .onAppear { AppUIState.shared.showingDiagnosticsWindow = true }
        .onDisappear { AppUIState.shared.showingDiagnosticsWindow = false }
        .onReceive(AppSettings.shared.$backupFolderURL) { newValue in
            guard newValue.path(percentEncoded: false) != "" else { return }
            self.backupFolderString = newValue.path(percentEncoded: false)
            self.backupFolderSet = true
        }
        .onReceive(AppSettings.shared.$vmwareFusionAppURL) { newValue in
            guard newValue.path(percentEncoded: false) != "" else { return }
            self.vmwareString = newValue.path(percentEncoded: false)
            self.vmwareSet = true
        }
        .onReceive(AppSettings.shared.$vmBundleURL) { newValue in
            guard newValue.path(percentEncoded: false) != "" else { return }
            self.vmbundleString = newValue.path(percentEncoded: false)
            self.vmbundleSet = true
        }
        .onReceive(AppSettings.shared.$vmIsReady) { newValue in
            self.vmIsReady = true
            self.vmButtonDisabled = false
        }
        .onReceive(AppSettings.shared.$vmKey) { newValue in
            self.vmKeyString = newValue
        }
        .onReceive(AppSettings.shared.$vmUser) { newValue in
            self.vmUserString = newValue
        }
        .onReceive(AppSettings.shared.$vmPasswd) { newValue in
            var string: String = ""
            for _ in 0..<newValue.count {
                string += "*"
            }
            self.vmPasswdString = string
        }
        .onReceive(AppSettings.shared.vm!.$lastBackupAttempt) { newValue in
            if let bool = newValue {
                vmLastBackupAttemptString = bool ? "success" : "fail"
            } else {
                vmLastBackupAttemptString = "nil"
            }
        }
    }
}
