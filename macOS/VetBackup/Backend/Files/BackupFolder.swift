//
//  BackupFolder.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2025-12-10.
//

import Combine
import Foundation

/**
 * The class representing the folder where the backup archives are stored. Subscribes to changes in this folder and assembles an observable array of `[BackupFile]`. Only includes files fitting the naming pattern specified for the backups.
 */
class BackupFolder: ObservableObject {
    @Published var files: [BackupFile] = []

    var url: URL
    private lazy var folderMonitor = FolderMonitor(url: self.url)

    init(url: URL) {
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
        print("\(timeStamp()) BackupFolder.handleChanges()")
        DispatchQueue.main.async {
            self.scanFolder()
        }
    }

    private func scanFolder() {
        print("\(timeStamp()) BackupFolder.scanFolder()")
        self.files = listBackupFiles(in: self.url)
    }

    /**
     * Refresh the metadata for files not fully uploaded to iCloud.
     */
    private func refreshUploadingFiles() {
        print("\(timeStamp()) BackupFolder.refreshUploadingFiles()")
        let uploadingFiles = files.filter { !$0.iCloudIsUploaded || $0.iCloudIsUploading }
//        guard !uploadingFiles.isEmpty else { return }
        print("\t-> there are \(uploadingFiles.count) files uploading")

        for file in uploadingFiles {
            print("\tobjectWillChange.send()")
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
        self.files.forEach { $0.refreshAttributes() }
    }

    func stopMonitoring() {
        print("\(timeStamp()) BackupFolder.stopMonitoring()")
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
 * Returns an array of `[BackupFile]` with the files sorted by date, `>`.
 */
func listBackupFiles(in url: URL) -> [BackupFile] {
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
