//
//  AppUIState.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-08-27.
//

import AppKit
import Combine
import Foundation

final class AppUIState {
    @Published var showingArchiveWindow: Bool = false { didSet { checkWindowsAndSetActivationPolicy() }}
    @Published var showingDiagnosticsWindow: Bool = false { didSet { checkWindowsAndSetActivationPolicy() }}
    @Published var showingSettingsWindow: Bool = false { didSet { checkWindowsAndSetActivationPolicy() }}
    @Published var showingSetupWindow: Bool = false { didSet { checkWindowsAndSetActivationPolicy() }}
    @Published var showingStatusWindow: Bool = false { didSet { checkWindowsAndSetActivationPolicy() }}

    static let shared = AppUIState()

    private func checkWindowsAndSetActivationPolicy() {
        if showingAnyWindow() { setActivationPolicy(to: .regular) }
        else { setActivationPolicy(to: .accessory) }
    }

    private func setActivationPolicy(to policy: NSApplication.ActivationPolicy) {
        guard NSApp.activationPolicy() != policy else { return }
        switch policy {
        case .accessory:
            NSApp.setActivationPolicy(.accessory)
            NSApp.deactivate()
        case .regular:
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        default:
            return
        }
    }

    private func showingAnyWindow() -> Bool {
        (showingArchiveWindow || showingDiagnosticsWindow || showingStatusWindow || showingSettingsWindow || showingSetupWindow)
    }
}
