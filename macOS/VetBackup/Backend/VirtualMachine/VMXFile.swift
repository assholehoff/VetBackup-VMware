//
//  VMXFile.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-08-01.
//

import Foundation

public class VMXFile: File {
    func diskFileUrl() -> URL {
        let diskFileUrl: URL
        if let diskFileName = valueFor(key: "nvme0:0.fileName") {
            diskFileUrl = self.url.deletingLastPathComponent().appendingPathComponent(diskFileName)
        } else {
            diskFileUrl = self.url.deletingLastPathComponent().appending(path: "Virtual Disk-000001-s001.vmdk")
        }
        return diskFileUrl
    }

    func path() -> String {
        return self.url.path(percentEncoded: false)
    }

    func valueFor(key: String) -> String? {
        try? parseFileFor(key: key, in: self.url)
    }

    private func parseFileFor(key: String, in url: URL) throws -> String? {
        let lines = try String(contentsOf: url, encoding: .utf8).split(separator: "\n")
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
}

func findVmxFile(in url: URL) -> VMXFile? {
    // extract VM name by removing `.vmwarevm` from lastPathComponent
    let vmxFileName: String = (url.lastPathComponent.removingPercentEncoding ?? url.lastPathComponent).dropLast(9).appending(".vmx")
    if FileManager.default.fileExists(atPath: url.appending(path: vmxFileName).path(percentEncoded: false)) {
        return VMXFile(url: url.appending(path: vmxFileName), created: nil)
    }

    // no file named VMname.vmx found in VM bundle, do a search and pick the vmx file in the directory
    if let urls = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: []) {
        for url in urls.filter({ $0.lastPathComponent.hasSuffix(".vmx") }) {
            // return the first match (should only be one)
            return VMXFile(url: url, created: nil)
        }
    }

    return nil
}
