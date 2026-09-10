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
    @State var deleteAlertIsPresented: Bool = false

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Mark outdated archives") {
                Log.app.debug("pressed \"Mark outdated archives\" button")
                AppSettings.shared.bf.folder?.updateOutdated()
            }
            .keyboardShortcut("r")
        }

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
