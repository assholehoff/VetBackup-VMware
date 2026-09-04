//
//  Folder.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2025-12-04.
//

import Combine
import Foundation

public class Folder: ObservableObject {
    @Published var files: Set<File> = []

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
            self.scanFolder()
        }
    }

    private func scanFolder() {
        var currentFiles: Set<File> = []
        let keys: [URLResourceKey] = [
            .creationDateKey,
            .contentModificationDateKey
        ]

        guard let urls = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: keys) else { return }

        // prune dead leaves
        let ids = urls.map({ $0.absoluteString })
        currentFiles = self.files.filter { file in
            ids.contains(file.id)
        }

        for url in urls {
            let id = url.absoluteString
            if !currentFiles.contains(where: { $0.id == id }) {
                let created = try? url.resourceValues(forKeys: [.creationDateKey]).creationDate
                let modified = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                currentFiles.insert(File(url: url, created: created ?? Date.distantPast))
            }
        }

        self.files = currentFiles
    }
}
