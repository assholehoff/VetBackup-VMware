//
//  FolderMonitor.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2025-12-07.
//

import Foundation

class FolderMonitor {
    // A FileDescriptor for the monitored directory
    private var monitoredFolderFileDescriptor: CInt = -1
    // A DispatchSource to monitor a FileDescriptor created from that directory
    private var folderMonitorSource: DispatchSourceFileSystemObject?
    // A DispatchQueue used for sending file changes in the directory
    private let folderMonitorQueue = DispatchQueue(label: "FolderMonitorQueue", attributes: .concurrent)
    
    let url: URL
    var folderDidChange: (() -> Void)?
    
    init(url: URL) {
        self.url = url
    }
    
    func startMonitoring() {
        guard folderMonitorSource == nil && monitoredFolderFileDescriptor == -1 else {
            return
        }
        
        // Open the folder referenced by the URL for monitoring only
        monitoredFolderFileDescriptor = open(url.path(), O_EVTONLY)
        
        // Define a dispatch source monitoring the folder for additions, deletions and renamings
        folderMonitorSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: monitoredFolderFileDescriptor, eventMask: .all, queue: folderMonitorQueue)
        
        // Define the block to call when a file change is detected
        folderMonitorSource?.setEventHandler { [weak self] in
            self?.folderDidChange?()
        }
        
        // Define a cancel handler to ensure the directory is closed when the source is cancelled
        folderMonitorSource?.setCancelHandler { [weak self] in
            guard let self = self else { return }
            close(self.monitoredFolderFileDescriptor)
            self.monitoredFolderFileDescriptor = -1
            self.folderMonitorSource = nil
        }
        
        // Start monitoring the directory via the source
        folderMonitorSource?.resume()
    }
    
    func stopMonitoring() {
        folderMonitorSource?.cancel()
    }
}
