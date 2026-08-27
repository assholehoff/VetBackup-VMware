 //
//  StatusView.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2025-12-06.
//

import SwiftUI
import UserNotifications

struct StatusView: View {
    @Environment(\.openSettings) private var openSettings
    @EnvironmentObject private var vmp: VMProvider
    @EnvironmentObject private var bfp: BFProvider
    
    @State var backupOngoing: Bool = false
    @State var backupStatusString: String = ""
    @State var lastBackupString: String = "No backup found"
    @State var nextBackupString: String = ""
    
    var body: some View {
        if let vm = vmp.vm {
            VStack {
                if vm.Authenticated() {
                    Image(.logotype)
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                        .padding(.bottom)
                    if lastBackupString != "No backup found" {
                        Text("Last backup done")
                        Text(lastBackupString)
                            .padding(.bottom)
                    } else {
                        Text("No backup found")
                    }
                    if backupOngoing {
                        ProgressView(backupStatusString)
                            .progressViewStyle(.circular)
                            .padding(.bottom)
                    } else {
                        Text("Next backup scheduled for")
                        Text(nextBackupString)
                            .padding(.bottom)
                        Button(action: {
                            _ = vm.Backup()
                        }, label: {
                            Text("Backup now")
                        })
                    }
                } else {
                    Button(action: {
                        NSApplication.shared.activate(ignoringOtherApps: true)
                        openSettings()
                    }, label: {
                        Text("Open Settings")
                    })
                }
            }
            .onAppear {
                lastBackupString = vm.LastBackupDate.formatted(date: .complete, time: .shortened)
                nextBackupString = vm.NextBackupDate().formatted(date: .complete, time: .shortened)
                backupOngoing = vm.BackupOngoing
            }
            .onReceive(vm.$BackupTime) { _ in
                nextBackupString = vm.NextBackupDate().formatted(date: .complete, time: .shortened)
            }
            .onReceive(vm.$BackupOngoing) { newValue in
                backupOngoing = newValue
                backupStatusString = newValue ? vm.NextBackupDate().formatted(date: .complete, time: .shortened) : ""
            }
            .padding()
        } else {
            LoadingView()
        }
    }
}
