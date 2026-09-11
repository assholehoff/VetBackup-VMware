//
//  ArchiveModel.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-09-10.
//

import SwiftUI

@Observable final class ArchiveModel {
    var files: [BackupFile] = []
    var outdatedFileIDs = Set<BackupFile.ID>()
    var selectedFileIDs = Set<BackupFile.ID>()
    var highlightOutdatedFiles: Bool = false
}
