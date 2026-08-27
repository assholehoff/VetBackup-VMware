//
//  VMProvider.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-08-10.
//

import Combine
import SwiftUI

final class BFProvider: ObservableObject {
    @AppStorage("BackupFolderURL") private var BackupFolderURL: URL =
        .documentsDirectory.appending(path: "VetVision", directoryHint: .isDirectory)
    @Published var bf: BackupFolder?

    @MainActor
    func setup() async {
        let instance = BackupFolder(url: BackupFolderURL)
        self.bf = instance
    }
}
