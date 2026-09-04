//
//  VetBackupApp.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-08-27.
//

import SwiftUI

@main
struct VetBackupApp: App {
    init() {
        registerUserDefaults()
    }
    var body: some Scene {
        MenuBarExtra("VetBackup", systemImage: "hare.fill") {
            ContentView()
                .overlay(alignment: .top) {
                    OverlayView()
                }
        }
        .menuBarExtraStyle(.window)
        Settings {
            SettingsView()
        }
        WindowGroup {
            ContentView()
                .onAppear { AppUIState.shared.showingStatusWindow = true }
                .onDisappear { AppUIState.shared.showingStatusWindow = false }
        }
        Window("Archive", id: "archive") {
            ArchiveView()
        }
        Window("Diagnostics", id: "diagnostics") {
            DiagnosticsView()
        }
    }
}
