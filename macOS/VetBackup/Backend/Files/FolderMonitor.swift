//
//  FolderMonitor.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-08-28.
//

import Foundation

/*
 All access and mutation of 'monitoredFolderFileDescriptor' and 'folderMonitorSource'
 are strictly isolated to 'folderMonitorQueue' for thread-safety, and should not require
 @MainActor isolation or main-thread access. All reads and writes to these properties
 occur only within 'folderMonitorQueue.async { ... }' blocks.
*/

class FolderMonitor: @unchecked Sendable {
    // A FileDescriptor for the monitored directory
    // Only accessed from within 'folderMonitorQueue'
    private var monitoredFolderFileDescriptor: CInt = -1
    // A DispatchSource to monitor a FileDescriptor created from that directory
    // Only accessed from within 'folderMonitorQueue'
    private var folderMonitorSource: DispatchSourceFileSystemObject?
    // A DispatchQueue used for sending file changes in the directory
    private let folderMonitorQueue = DispatchQueue(label: "FolderMonitorQueue", attributes: .concurrent)

    let url: URL
    var folderDidChange: (() -> Void)?

    init(url: URL) {
        self.url = url
    }

    func startMonitoring() {
        folderMonitorQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.folderMonitorSource == nil && self.monitoredFolderFileDescriptor == -1 else {
                return
            }
            self.monitoredFolderFileDescriptor = open(self.url.path(), O_EVTONLY)
            self.folderMonitorSource = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: self.monitoredFolderFileDescriptor,
                eventMask: .all,
                queue: self.folderMonitorQueue
            )
            self.folderMonitorSource?.setEventHandler {
                self.folderDidChange?()
            }
            self.folderMonitorSource?.setCancelHandler {
                close(self.monitoredFolderFileDescriptor)
                self.monitoredFolderFileDescriptor = -1
                self.folderMonitorSource = nil
            }
            self.folderMonitorSource?.resume()
        }
    }

    func stopMonitoring() {
        folderMonitorQueue.async { [weak self] in
            self?.folderMonitorSource?.cancel()
        }
    }
}
