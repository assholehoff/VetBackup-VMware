//
//  StatusView.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-08-27.
//

import SwiftUI

struct StatusView: View {
    @State var backupButtonDisabled: Bool = !AppSettings.shared.canBackup
    @State var backupOngoing: Bool = false
    @State var lastBackup: Date = AppSettings.shared.lastBackupDate
    @State var nextBackup: Date = AppSettings.shared.nextBackupDate

    var body: some View {
        VStack(spacing: 16) {
            Image(.logotype)
                .imageScale(.large)
                .foregroundStyle(.tint)
                .padding()
            if lastBackup != .distantPast {
                VStack {
                    Text("Last backup done")
                    Text(lastBackup.formatted(date: .long, time: .standard))
                }
            }
            if backupOngoing {
                ProgressView("Backup ongoing...")
                    .controlSize(.extraLarge)
                    .progressViewStyle(.circular)
            } else {
                if nextBackup != .distantPast {
                    VStack {
                        Text("Next backup scheduled for")
                        Text(nextBackup.formatted(date: .long, time: .standard))
                    }
                }
            }
            Button("Backup now") {
                backupButtonDisabled = true
                Task {
                    await AppSettings.shared.vm?.backup()
                }
            }
            .disabled(backupButtonDisabled)
        }
        .frame(minWidth: 200)
        .padding()
        .onReceive(AppSettings.shared.$backupOngoing) { newValue in
            backupOngoing = newValue
        }
        .onReceive(AppSettings.shared.$canBackup) { newValue in
            backupButtonDisabled = !newValue
        }
        .onReceive(AppSettings.shared.$lastBackupDate) { newValue in
            lastBackup = newValue
        }
        .onReceive(AppSettings.shared.$nextBackupDate) { newValue in
            nextBackup = newValue
        }
    }
}
