//
//  BFProvider.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-08-29.
//

import Combine
import SwiftUI

/**
 * BackupFolder Provider
 */
final class BFProvider: ObservableObject {
    @Published var isLoaded: Bool = false
    @Published var folder: BackupFolder?

    func setup(url: URL) async {
        guard url.absoluteString != "file:///" else { return }
        print("BFProvider.setup()")
        await MainActor.run {
            folder?.stopMonitoring()
            self.folder = BackupFolder(url: url)
            self.isLoaded = true
        }
    }
}
