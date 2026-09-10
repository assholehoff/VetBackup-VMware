//
//  VetBackupApp.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-08-27.
//

import os
import SwiftUI

@main
struct VetBackupApp: App {
    init() {
        Log.app.debug("VetBackupApp.init()")
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
        .commands {
            ArchiveCommands()
        }
        Window("Diagnostics", id: "diagnostics") {
            DiagnosticsView()
        }
        .commands {
            // DiagnosticsCommands()
        }
    }
}
