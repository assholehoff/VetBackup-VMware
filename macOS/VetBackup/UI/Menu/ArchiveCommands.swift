//
//  AppCommands.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-09-10.
//

import os
import SwiftUI

struct ArchiveCommands: Commands {
    @Environment(\.openWindow) var openWindow
    @FocusedValue(ArchiveModel.self) private var archiveModel: ArchiveModel?

    var body: some Commands {
        CommandGroup(replacing: .singleWindowList) {}

        CommandGroup(replacing: .windowList) {
            Button("Archive") {
                openWindow(id: "archive")
            }
            .keyboardShortcut("1")

            Button("Diagnostics") {
                openWindow(id: "diagnostics")
            }
            .keyboardShortcut("0")
        }
    }
}
