//
//  AppUIState.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-08-27.
//

import AppKit
import Combine
import Foundation
import os

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
            Log.app.debug("set NSApplication.ActivationPolicy to .accessory")
            NSApp.setActivationPolicy(.accessory)
            NSApp.deactivate()
        case .regular:
            Log.app.debug("set NSApplication.ActivationPolicy to .regular")
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        default:
            Log.app.debug("AppUIState.setActivationPolicy policy switch defaulted! this should not be possible!")
            return
        }
    }

    private func showingAnyWindow() -> Bool {
        (showingArchiveWindow || showingDiagnosticsWindow || showingStatusWindow || showingSettingsWindow || showingSetupWindow)
    }
}
