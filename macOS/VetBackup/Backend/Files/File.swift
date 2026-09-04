//
//  File.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-06-21.
//

import Foundation

public class File: Hashable, Identifiable {
    public let id: String
    public var url: URL
    let name: String
    var created: Date?
    var modified: Date?

    init(url: URL, created: Date?) {
        self.id = url.absoluteString
        self.url = url
        self.name = url.lastPathComponent.removingPercentEncoding ?? url.lastPathComponent

        if created == nil,
           let createdFromMetadata = try? url.resourceValues(forKeys: [.creationDateKey]).creationDate {
            self.created = createdFromMetadata
        } else {
            self.created = created
        }
    }

    static public func ==(a: File, b: File) -> Bool {
        a.id == b.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }

    public func exists() -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    public func refreshAttributes() -> Bool {
        let keys: Set<URLResourceKey> = [.creationDateKey, .contentModificationDateKey]
        if let values = try? url.resourceValues(forKeys: keys) {
            self.created = values.creationDate
            self.modified = values.contentModificationDate
            return true
        }
        return false
    }
}

