//
//  Folder.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2025-12-07.
//

import Combine
import Foundation

class Folder: ObservableObject {
    @Published var files: [URL] = []

    var url: URL
    private lazy var folderMonitor = FolderMonitor(url: self.url)

    init(url: URL) {
        self.url = url
        folderMonitor.folderDidChange = { [weak self] in
            print("folderDidChange()")
            self?.handleChanges()
        }
        folderMonitor.startMonitoring()
        self.handleChanges()
    }

    func handleChanges() {
        let files = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .producesRelativePathURLs)) ?? []
        DispatchQueue.main.async {
            self.files = files
        }
    }
}
