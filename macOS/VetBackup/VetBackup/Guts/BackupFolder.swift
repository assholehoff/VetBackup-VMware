//
//  BackupFolder.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2025-12-10.
//

import Combine
import Foundation

class BackupFolder: ObservableObject {
    @Published var files: [BackupFile] = []
    
    var url: URL
    private lazy var folderMonitor = FolderMonitor(url: self.url)
    
    init(url: URL) {
        self.url = url
        folderMonitor.folderDidChange = { [weak self] in
            self?.handleChanges()
        }
        folderMonitor.startMonitoring()
        self.handleChanges()
    }
    
    func handleChanges() {
        DispatchQueue.main.async {
            self.files = BackupFilesIn(url: self.url)
        }
    }
}
