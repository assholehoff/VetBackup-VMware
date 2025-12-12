//
//  VetBackupApp.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2025-11-28.
//

import SwiftUI

@main
struct VetBackupApp: App {
    @AppStorage("BackupFolderURL") private var BackupFolderURL: URL =
        .documentsDirectory.appending(path: "VetVision", directoryHint: .isDirectory)
    
    var body: some Scene {
        @ObservedObject var folder: BackupFolder = BackupFolder(url: BackupFolderURL)
        
        MenuBarExtra("VetBackup", systemImage: "hare.fill") {
            ContentView(folder: folder)
        }
        .menuBarExtraStyle(.window)
        Settings {
            SettingsView()
        }
        Window("Backups", id: "backupWindow") {
            BackupView(folder: folder)
                .frame(minWidth: 704, minHeight: 360)
        }
        .windowResizability(.automatic)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Backup now", systemImage: "play.fill") {}
                    .keyboardShortcut("B")
            }
            CommandMenu("Backups") {
                Button("Old backups", systemImage: "house.fill") {}
                    .keyboardShortcut("O")
            }
        }
    }
}
