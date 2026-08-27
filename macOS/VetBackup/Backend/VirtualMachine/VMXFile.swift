//
//  VMXFile.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-08-01.
//

import Foundation

public class VMXFile: File {
    func DiskFileURL() -> URL {
        if let diskFileName = try? valueForKey("nvme0:0.fileName", inVMXPath: self.id) {
            print("found diskfile: \(self.id.deletingLastPathComponent().appendingPathComponent(diskFileName))")
            return self.id.deletingLastPathComponent().appendingPathComponent(diskFileName)
        }
        print("defaulting to generic: \(self.id.deletingLastPathComponent().appending(path: "Virtual Disk-000001-s001.vmdk"))")
        return self.id.deletingLastPathComponent().appending(path: "Virtual Disk-000001-s001.vmdk")
    }
    func Path() -> String {
        return id.path(percentEncoded: false)
    }
}

func valueForKey(_ key: String, inVMXPath path: URL) throws -> String? {
    let lines = try String(contentsOf: path, encoding: .utf8).split(separator: "\n")
    for line in lines {
        if line.trimmingCharacters(in: .whitespaces).hasPrefix(key + " =") {
            // Extract the value after the '=' and remove quotes and whitespace
            let parts = line.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                let value = parts[1]
                    .trimmingCharacters(in: .whitespaces)
                    .trimmingCharacters(in: .init(charactersIn: "\""))
                return value
            }
        }
    }
    return nil
}
