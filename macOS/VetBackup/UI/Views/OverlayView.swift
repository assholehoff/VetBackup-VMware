//
//  OverlayView.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-08-30.
//

import SwiftUI

struct OverlayView: View {
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow

    @State var canQuit: Bool = AppSettings.shared.canQuit

    init() {
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Button("Archive", systemImage: "archivebox") {
                if AppUIState.shared.showingArchiveWindow {
                    NSApp.activate(ignoringOtherApps: true)
                }
                openWindow(id: "archive")
            }
            .buttonStyle(.plain)
            .labelStyle(.iconOnly)
            Spacer()
            Button("Settings", systemImage: "gear") {
                if AppUIState.shared.showingSettingsWindow {
                    NSApp.activate(ignoringOtherApps: true)
                }
                openSettings()
            }
            .buttonStyle(.plain)
            .labelStyle(.iconOnly)
            Button("Quit", systemImage: "xmark.circle.fill") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.plain)
            .disabled(!canQuit)
            .labelStyle(.iconOnly)
        }
        .onReceive(AppSettings.shared.$canQuit) { newValue in
            canQuit = newValue
        }
        .padding(8)
    }
}
