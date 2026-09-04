//
//  VMSettings.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-08-29.
//

import Foundation

struct VMSettings {
    let backupFolderURL: URL
    let dailyBackupTime: Date

    /**
     * Returns **true** if App has read/write access to backupFolderUrl
     */
    func verifyBackupFolderURL() throws -> Bool {
        let folderURL = self.backupFolderURL
        var success: Bool = false
        let fileURL = folderURL.appending(path: UUID().uuidString)
        if FileManager.default.createFile(atPath: fileURL.path(percentEncoded: false), contents: nil) {
            try FileManager.default.removeItem(at: fileURL)
            success = true
        }
        return success
    }
}
