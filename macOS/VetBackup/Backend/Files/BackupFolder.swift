//
//  BackupFolder.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2025-12-10.
//

import Combine
import Foundation
import os

/**
 * The class representing the folder where the backup archives are stored.
 *
 * Subscribes to changes in this folder and assembles an observable array of `[BackupFile]`.
 * Only includes files fitting the naming pattern specified for the backups.
 */
class BackupFolder: ObservableObject {
    @Published var files: [BackupFile] = [] { didSet {
        var size: Int64 = 0
        for file in files {
            size += file.size
        }
        self.size = size
        Task { self.updateOutdated() }
    }}
    @Published var selection: Set<BackupFile.ID> = [] { didSet {
        var selectedSize: Int64 = 0
        for file in files {
            if selection.contains(file.id) {
                selectedSize += file.size
            }
        }
        self.selectedSize = selectedSize
        Log.backend.info("\(self.selection.count) selected files occupy \(sizeString(bytes: self.selectedSize))")
    }}
    @Published var outdated: Set<BackupFile.ID> = [] { didSet {
        var outdatedSize: Int64 = 0
        for file in files {
            if outdated.contains(file.id) {
                outdatedSize += file.size
            }
        }
        self.outdatedSize = outdatedSize
        Log.backend.info("\(self.outdated.count) outdated files occupy \(sizeString(bytes: self.outdatedSize))")
    }}
    @Published var size: Int64 = 0
    @Published var selectedSize: Int64 = 0
    @Published var outdatedSize: Int64 = 0

    var url: URL
    private lazy var folderMonitor = FolderMonitor(url: self.url)

    init(url: URL) {
        Log.backend.debug("BackupFolder.init(url: \(url.absoluteString)")
        self.url = url
        folderMonitor.folderDidChange = { [weak self] in
            self?.handleChanges()
        }
        if Thread.isMainThread {
            folderMonitor.startMonitoring()
        } else {
            DispatchQueue.main.async { [folderMonitor] in
                folderMonitor.startMonitoring()
            }
        }
        self.handleChanges()
    }

    func handleChanges() {
        Log.backend.debug("BackupFolder.handleChanges()")
        DispatchQueue.main.async {
            self.scanFolder()
        }
    }

    func identifyOutdatedFiles() -> Set<BackupFile.ID> {
        Log.backend.info("BackupFolder.identifyOutdatedFiles()")
        guard files.count > 10 else {
            Log.backend.info("there are fewer than 10 files, will not delete any")
            return []
        }

        guard let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: .now),
              let lastFortnight = Calendar.current.date(byAdding: .day, value: -14, to: .now),
              let lastSixMonths = Calendar.current.date(byAdding: .month, value: -6, to: .now)
        else { return [] }

        let recentFiles = files.filter { $0.date >= lastWeek }
        let mediumFiles = files.filter { $0.date < lastWeek && $0.date >= lastFortnight }
        let oldFiles = files.filter { $0.date < lastFortnight }

        let keepRecent = Set(recentFiles.map { $0.id })

        let keepMedium = Set(mediumFiles
            .sorted(by: { $0.date > $1.date })
            .prefix(3)
            .map { $0.id }
        )

        let keepOld = Set(oldFiles
            .filter { $0.date >= lastSixMonths }
            .reduce(into: [String: BackupFile]()) { dict, file in
                let components = Calendar.current.dateComponents([.year, .month], from: file.date)
                let key = "\(components.year!)-\(components.month!)"

                if let existing = dict[key], file.date < existing.date {
                    dict[key] = file
                } else {
                    dict[key] = file
                }
            }
            .values
            .map { $0.id }
        )

        let allKeepers = keepRecent.union(keepMedium).union(keepOld)

        let allIds = Set(files.map { $0.id })
        let deleteProposal = allIds.subtracting(allKeepers)

        return deleteProposal
    }

    func updateOutdated() {
        Log.backend.debug("BackupFolder.updateOutdated()")
        let outdated = identifyOutdatedFiles()
        for file in files {
            if outdated.contains(file.id) {
                file.isOutdated = true
            }
        }
        self.outdated = outdated
    }

    func deleteOutdated() -> Bool {
        Log.backend.debug("BackupFolder.deleteOutdated()")
        Log.backend.info("BackupFolder.deleteOutdated() if performed, this operation will free \(sizeString(bytes: self.outdatedSize, ))")
        let outdatedFiles = files.filter({ $0.isOutdated })
        do {
            for file in outdatedFiles {
                try FileManager.default.removeItem(at: file.url)
            }
        } catch {
            Log.backup.error("BackupFolder.deleteOutdated() error: \(error)")
            return false
        }
        return true
    }

    private func scanFolder() {
        Log.backend.debug("BackupFolder.scanFolder()")
        self.files = listBackupFiles(in: self.url)
    }

    /**
     * Refresh the metadata for files not fully uploaded to iCloud.
     */
    private func refreshUploadingFiles() {
        Log.backend.debug("BackupFolder.refreshUploadingFiles()")
        let uploadingFiles = files.filter { !$0.iCloudIsUploaded || $0.iCloudIsUploading }
//        guard !uploadingFiles.isEmpty else { return }
        Log.backend.info("BackupFolder.refreshUploadingFiles() there are \(uploadingFiles.count) files uploading")

        for file in uploadingFiles {
            Log.backend.debug("BackupFolder.refreshUploadingFiles().objectWillChange.send()")
            objectWillChange.send()
            file.refreshAttributes()
        }

        if uploadingFiles.contains(where:  { !$0.iCloudIsUploaded }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.refreshUploadingFiles()
            }
        }
    }

    func refreshAttributes() {
        Log.backend.debug("BackupFolder.refreshAttributes()")
        self.files.forEach { $0.refreshAttributes() }
    }

    func stopMonitoring() {
        Log.backend.debug("BackupFolder.stopMonitoring()")
        if Thread.isMainThread {
            folderMonitor.stopMonitoring()
        } else {
            DispatchQueue.main.async { [folderMonitor] in
                folderMonitor.stopMonitoring()
            }
        }
    }
}

/**
 * A neatly formatted human friendly size string
 */
func sizeString(bytes: Int64) -> String {
    Log.backend.debug("sizeString(bytes:)")
    let bcf = ByteCountFormatter()
    bcf.allowedUnits = [.useAll]
    bcf.countStyle = .file
    return bcf.string(fromByteCount: bytes)
}

/**
 * Returns an array of `[BackupFile]` with the files sorted by date, `>`.
 */
func listBackupFiles(in url: URL) -> [BackupFile] {
    Log.backend.debug("listBackupFiles(in: \(url.absoluteString)")
    let keys: [URLResourceKey] = [
        .fileSizeKey,
        .creationDateKey,
        .contentModificationDateKey,
        .ubiquitousItemIsUploadedKey,
        .ubiquitousItemIsUploadingKey
    ]
    var backupFiles: [BackupFile] = []
    guard let urls = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: keys).filter({ fileUrl in
        fileUrl.path(percentEncoded: false).contains(/DVS-\d{8}-\d{6}\.zip/)
    }) else { return backupFiles }
    backupFiles = urls.map({ BackupFile(url: $0) })
    print("\(timeStamp()) listBackupFiles(in: \(url.path(percentEncoded: false))) found \(backupFiles.count) files")
    return backupFiles.sorted(by: { $0.date > $1.date })
}
