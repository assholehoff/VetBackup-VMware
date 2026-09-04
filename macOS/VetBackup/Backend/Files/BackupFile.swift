//
//  BackupFile.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2025-12-04.
//

import Combine
import Foundation
import System

public class BackupFile: File, ObservableObject {
    let format: String = "yyyyMMdd-HHmmss"
    let date: Date // NOTE: this is the date for the database backup, which may differ from modified/created

    @Published var size: Int64

    @Published var iCloudIsUploaded: Bool = false
    @Published var iCloudIsUploading: Bool = false
    @Published var lanUploaded: Bool
    @Published var lanIsUploading: Bool

    private var monitorTask: Task<Void, Never>?

    public init(url: URL) {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false))
        self.date = getDate(from: url.lastPathComponent)
        self.size = attributes?[FileAttributeKey.size] as? Int64 ?? 0

        let keys: Set<URLResourceKey> = [
            .fileSizeKey,
            .ubiquitousItemIsUploadedKey,
            .ubiquitousItemIsUploadingKey
        ]

        if let values = try? url.resourceValues(forKeys: keys) {
            self.iCloudIsUploaded = values.ubiquitousItemIsUploaded ?? false
            self.iCloudIsUploading = values.ubiquitousItemIsUploading ?? false
        }

        self.lanUploaded = false
        self.lanIsUploading = false

        super.init(url: url, created: nil)
    }

    /**
     * Returns values for `.fileSizeKey`, `.ubiquitousItemIsUploadedKey` and `.ubiquitousItemIsUploadedKey`
     *
     * Defaults to `(size: 0, uploaded: false, uploading: false)`
     */
    private func fetchResourceValues() async -> (size: Int64, uploaded: Bool, uploading: Bool) {
        var sizeInt64: Int64 = 0
        var uploaded: Bool = false
        var uploading: Bool = false
        let keys: Set<URLResourceKey> = [
            .fileSizeKey,
            .ubiquitousItemIsUploadedKey,
            .ubiquitousItemIsUploadingKey
        ]
        url.removeAllCachedResourceValues() // NOTE: <- possibly done in calling function on Main thread instead (?)
        if let values = try? url.resourceValues(forKeys: keys) {
            if let value = values.fileSize {
                sizeInt64 = Int64(value)
            }
            if let value = values.ubiquitousItemIsUploaded {
                uploaded = value
            }
            if let value = values.ubiquitousItemIsUploading {
                uploading = value
            }
        }
        return (sizeInt64, uploaded, uploading)
    }

    override public func refreshAttributes() -> Bool {
        print("\(timeStamp()) \(self.name).refreshAttributes()")
        var somethingChanged: Bool = false
        // TODO: implement .lanUploaded and .lanIsUploading to FreeBSD server
        let keys: Set<URLResourceKey> = [
            .fileSizeKey,
            .creationDateKey,
            .contentModificationDateKey,
            .ubiquitousItemIsUploadedKey,
            .ubiquitousItemIsUploadingKey
        ]

        url.removeAllCachedResourceValues()

        if let values = try? url.resourceValues(forKeys: keys) {
            print("\tgot values for keys")
            if self.created != values.creationDate {
                print("\tcreated changed")
                self.created = values.creationDate
                somethingChanged = true
            }

            if self.modified != values.contentModificationDate {
                print("\tmodified changed")
                self.modified = values.contentModificationDate
                somethingChanged = true
            }

            if let uploaded = values.ubiquitousItemIsUploaded,
               self.iCloudIsUploaded != uploaded {
                print("\tiCloudIsUploaded changed")
                self.iCloudIsUploaded = uploaded
                somethingChanged = true
            }

            if let uploading = values.ubiquitousItemIsUploading,
               self.iCloudIsUploading != uploading {
                print("\tiCloudIsUploading changed")
                self.iCloudIsUploading = uploading
                somethingChanged = true
            }

            if let sizeValue = values.fileSize {
                let sizeInt64 = Int64(sizeValue)
                if self.size != sizeInt64 {
                    print("\tsize changed")
                    self.size = sizeInt64
                    somethingChanged = true
                }
            }
        }
        print("\(timeStamp()) \(self.name).refreshAttributes() -> \(somethingChanged)")
        return somethingChanged
    }

    public func sizeString() -> String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useAll]
        bcf.countStyle = .file
        return bcf.string(fromByteCount: self.size)
    }

    /**
     * Start monitoring `URLResourceValues` for the keys `.fileSizeKey`,
     * `.ubiquitousItemIsUploadedKey` and `.ubiquitousItemIsUploadingKey`
     *
     * These are the two keys associated with **iCloud** upload status.
     */
    public func startMonitoring() {
        monitorTask?.cancel()

        monitorTask = Task.detached(priority: .background) { [weak self] in
            while !Task.isCancelled {
                if let values = await self?.fetchResourceValues() {
                    await MainActor.run {
                        if self?.size != values.size {
                            self?.size = values.size
                        }
                        if self?.iCloudIsUploaded != values.uploaded {
                            self?.iCloudIsUploaded = values.uploaded
                        }
                        if self?.iCloudIsUploading != values.uploading {
                            self?.iCloudIsUploading = values.uploading
                        }
                    }
                }

                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    public func stopMonitoring() {
        monitorTask?.cancel()
        monitorTask = nil
    }
}
