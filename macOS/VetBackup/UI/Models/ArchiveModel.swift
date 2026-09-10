//
//  ArchiveModel.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-09-10.
//

import SwiftUI

@Observable final class ArchiveModel {
    var files: Set<BackupFile.ID> = []
    var outdated: Set<BackupFile.ID> = []
    var selected: Set<BackupFile.ID> = []
}
