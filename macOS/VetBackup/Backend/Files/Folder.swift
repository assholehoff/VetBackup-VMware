//
//  BackupFile.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2025-12-04.
//

import Foundation
import System

public class BackupFile: File {
    let dateFormat: String = "yyyyMMdd-HHmmss"
    let date: Date
    let size: Int64
    
    var iCloudUploaded: Bool
    var iCloudIsUploading: Bool
    var lanUploaded: Bool
    var lanIsUploading: Bool
    
    override init(url: URL) {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false))
        self.date = getDateFrom(name: url.lastPathComponent)
        self.size = attributes![FileAttributeKey.size] as? Int64 ?? 0
        
        self.iCloudUploaded = (try? url.resourceValues(forKeys: [.ubiquitousItemIsUploadedKey]).ubiquitousItemIsUploaded ?? false) ?? false
        self.iCloudIsUploading = (try? url.resourceValues(forKeys: [.ubiquitousItemIsUploadingKey]).ubiquitousItemIsUploading ?? false) ?? false
        self.lanUploaded = false
        self.lanIsUploading = false
        
        super.init(url: url)
    }
    
    public func sizeString() -> String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useAll]
        bcf.countStyle = .file
        return bcf.string(fromByteCount: self.size)
    }
}

private func getDateFrom(name: String) -> Date {
    return getDateFrom(name: name, dateFormat: "yyyyMMdd-HHmmss")
}

private func getDateFrom(name: String, dateFormat: String) -> Date {
    let df = DateFormatter()
    df.dateFormat = dateFormat
    return df.date(from: name.replacingOccurrences(of: "DVS-", with: "").replacingOccurrences(of: ".zip", with: "")) ?? Date(timeIntervalSince1970: 0)
}

public func listBackupFilesIn(folder: URL) -> [BackupFile] {
    if !FileManager.default.fileExists(atPath: folder.path(percentEncoded: false)) {
        return [BackupFile]()
    }
    // Regex literal - should be the fastest function
    let urls = try! FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: []).filter { file in
        file.path(percentEncoded: false).contains(/DVS-\d{8}-\d{6}\.zip/)
    }.sorted(by: {
        $0.lastPathComponent > $1.lastPathComponent
    })
    return urls.map { url in
        BackupFile(url: url)
    }
}

private func escapeRegexChars(inString: String) -> String {
    // replace all of: .^$*+?()[]{}\|
    var string: String = inString
    string = string.replacingOccurrences(of: "\\", with: "\\\\")
    string = string.replacingOccurrences(of: ".", with: "\\.")
    string = string.replacingOccurrences(of: "^", with: "\\^")
    string = string.replacingOccurrences(of: "$", with: "\\$")
    string = string.replacingOccurrences(of: "*", with: "\\*")
    string = string.replacingOccurrences(of: "+", with: "\\+")
    string = string.replacingOccurrences(of: "?", with: "\\?")
    string = string.replacingOccurrences(of: "(", with: "\\(")
    string = string.replacingOccurrences(of: ")", with: "\\)")
    string = string.replacingOccurrences(of: "[", with: "\\[")
    string = string.replacingOccurrences(of: "]", with: "\\]")
    string = string.replacingOccurrences(of: "{", with: "\\{")
    string = string.replacingOccurrences(of: "}", with: "\\}")
    string = string.replacingOccurrences(of: "|", with: "\\|")
    return string
}

private func replaceDateRegex(fromString: String) -> String {
    var string: String = fromString
    string = string.replacingOccurrences(of: "yyyy", with: "\\d{4}")
    string = string.replacingOccurrences(of: "MM", with: "[0-1]{1}[0-9]{1}")
    string = string.replacingOccurrences(of: "dd", with: "[0-3]{1}[0-9]{1}")
    string = string.replacingOccurrences(of: "HH", with: "[0-2]{1}[0-9]{1}")
    string = string.replacingOccurrences(of: "mm", with: "[0-5]{1}[0-9]{1}")
    string = string.replacingOccurrences(of: "ss", with: "[0-5]{1}[0-9]{1}")
    return string
}

private func dateRegex(dateFormat: String, prefix: String, suffix: String) -> Regex<AnyRegexOutput> {
    let string: String = replaceDateRegex(fromString: escapeRegexChars(inString: dateFormat))
    let pfx: String = escapeRegexChars(inString: prefix)
    let sfx: String = escapeRegexChars(inString: suffix)
    guard let regex = try? Regex(pfx + string + sfx) else { return try! Regex("DVS-\\d{8}-\\d{6}\\.zip") }
    print(pfx+string+sfx)
    return regex
}
