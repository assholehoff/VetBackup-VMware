//
//  FocusedValue.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-09-11.
//

import SwiftUI

extension FocusedValues {
    @Entry var selectedFileIDs: Set<BackupFile.ID>?
    @Entry var outdatedFileIDs: Set<BackupFile.ID>?
    @Entry var highlightOutdatedFiles: Bool?
}
