//
//  BackupFile.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2025-12-04.
//

import Foundation
import System

public struct BackupFile: Identifiable {
    public let id: String
    
    let date: Date
    let url: URL
    let size: Int64
    
    let icloudUploaded: Bool
    let icloudIsUploading: Bool
    let lanUploaded: Bool
    let lanIsUploading: Bool
    
    init() {
        self.id = ""
        self.date = Date(timeIntervalSince1970: 0)
        self.size = 0
        self.url = .temporaryDirectory
        self.icloudUploaded = false
        self.icloudIsUploading = false
        self.lanUploaded = false // TODO implement xattr com.ad.vetbackup.lanuploaded: Bool
        self.lanIsUploading = false // TODO implement xattr com.ad.vetbackup.lanisuploading: Bool
    }
    
    public init(url: URL) {
        self.init(url: url, dateFormat: "yyyyMMdd-HHmmss")
    }
    public init(url: URL, dateFormat: String) {
        self.init(url: url, dateFormat: dateFormat, prefix: "DVS-")
    }
    public init(url: URL, dateFormat: String, prefix: String) {
        self.init(url: url, dateFormat: dateFormat, prefix: prefix, suffix: ".zip")
    }
    public init(url: URL, dateFormat: String, prefix: String, suffix: String) {
        let fm = FileManager.default
        let attr = try? fm.attributesOfItem(atPath: url.path(percentEncoded: false))
        
        var name: String = FilePath(url.path(percentEncoded: false)).lastComponent!.string
        name = String(name.dropFirst(prefix.count))
        name = String(name.dropLast(suffix.count))
        
        self.id = url.lastPathComponent
        self.date = getDateFrom(name: name, dateFormat: dateFormat)
        self.size = attr?[FileAttributeKey.size] as? Int64 ?? 0
        self.url = url
        self.icloudUploaded = (try? url.resourceValues(forKeys: [.ubiquitousItemIsUploadedKey]).ubiquitousItemIsUploaded ?? false) ?? false
        self.icloudIsUploading = (try? url.resourceValues(forKeys: [.ubiquitousItemIsUploadingKey]).ubiquitousItemIsUploading ?? false) ?? false
        self.lanUploaded = false
        self.lanIsUploading = false
    }
    
    public func Size() -> String {
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
    return df.date(from: name) ?? Date(timeIntervalSince1970: 0)
}

public func BackupFilesIn(url: URL) -> [BackupFile] {
    if !FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
        return [BackupFile]()
    }
    // Regex literal - should be the fastest function
    let urls = try! FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: []).filter { file in
        file.path(percentEncoded: false).contains(/DVS-\d{8}-\d{6}\.zip/)
    }.sorted(by: {
        $0.lastPathComponent > $1.lastPathComponent
    })
    return urls.map { file in
        BackupFile(url: file)
    }
}

public func BackupFilesIn(url: URL, dateFormat: String) -> [BackupFile] {
    // NB: creating a regex from strings at runtime is slower than using a regex literal
    return BackupFilesIn(url: url, dateFormat: dateFormat, prefix: "DVS-", suffix: ".zip")
}

public func BackupFilesIn(url: URL, dateFormat: String, prefix: String) -> [BackupFile] {
    // NB: creating a regex from strings at runtime is slower than using a regex literal
    return BackupFilesIn(url: url, dateFormat: dateFormat, prefix: prefix, suffix: ".zip")
}

public func BackupFilesIn(url: URL, dateFormat: String, prefix: String, suffix: String) -> [BackupFile] {
    if !FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
        return [BackupFile]()
    }
    // NB: creating a regex from strings at runtime is slower than using a regex literal
    var files: [BackupFile] = []
    let fm = FileManager.default
    do {
        let content = try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: [])
        let dateRegex = dateRegex(dateFormat: dateFormat, prefix: prefix, suffix: suffix)
        for file in content {
            if try dateRegex.wholeMatch(in: file.lastPathComponent) != nil {
                files.append(BackupFile(url: file, dateFormat: dateFormat, prefix: prefix, suffix: suffix))
                print("appended \(file.lastPathComponent) to files")
            }
        }
    } catch {
        print("error: \(error)")
    }
    return files
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
