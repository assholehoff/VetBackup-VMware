//
//  VMXFile.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-08-01.
//

import Foundation

/**
 * The `vmx` file contains the settings for a VMware Fusion virtual machine. This file is parsed for the name of the disk file, so that can be used for imprecise modification checks when the VM is offline.
 */
public class VMXFile: File {
    /**
     * Returns a URL for the disk file.
     *
     * If the key `nvme0:0.fileName` can't be found it defaults to `Virtual Disk-000001-s001.vmdk`.
     *
     * **TODO: make this more robust.** Consider throwing or returning `nil` when no file can be reliably established.
     */
    func diskFileUrl() -> URL {
        let diskFileUrl: URL
        if let diskFileName = valueFor(key: "nvme0:0.fileName") {
            diskFileUrl = self.url.deletingLastPathComponent().appendingPathComponent(diskFileName)
        } else {
            diskFileUrl = self.url.deletingLastPathComponent().appending(path: "Virtual Disk-000001-s001.vmdk")
        }
        return diskFileUrl
    }

    /** Return the path with any percent encoding removed. */
    func path() -> String {
        return self.url.path(percentEncoded: false)
    }

    /** Return the string value for the key string, or `nil` if not found.  */
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

/**
 * The `vmx` for the `vmwarevm` bundle.
 *
 * Parse folder at `url` and return a `VMXFile` representing
 * the `vmx` with the same base name as the `vmwarevm` bundle supplied in `url`.
 * Or, _the first_ `vmx` it finds if none with the same base name is found.
 * Returns `nil` if **no** `vmx` can be found.
 */
func findVmxFile(inBundle url: URL) -> VMXFile? {
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
