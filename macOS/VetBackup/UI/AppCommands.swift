//
//  AppCommands.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-09-10.
//

import os
import SwiftUI

struct ArchiveCommands: Commands {
    @FocusedValue(ArchiveModel.self) private var archiveModel: ArchiveModel?

    var body: some Commands {
        @Environment(\.openWindow) var openWindow
        CommandGroup(after: .newItem) {
            Button("Mark outdated archives") {
                Log.app.debug("pressed \"Mark outdated archives\" button")
                AppSettings.shared.bf.folder?.markOutdated()
            }
//            .disabled(archiveModel == nil)
            .keyboardShortcut("r")
            Button("Delete outdated archives") {
                Log.app.debug("pressed \"Mark outdated archives\" button")
                AppSettings.shared.bf.folder?.markOutdated()
            }
//            .disabled(archiveModel == nil || ((archiveModel?.outdated.isEmpty) != nil))
            .keyboardShortcut("d")
            Button("Rescan backup folder") {
                Log.app.debug("pressed \"rescan")
            }
        }
        CommandGroup(replacing: .singleWindowList) {
            Button("Diagnostics") {
                openWindow(id: "diagnostics")
            }
            .keyboardShortcut("0")
            Button("Archive") {
                openWindow(id: "archive")
            }
            .keyboardShortcut("1")
        }
    }
}
