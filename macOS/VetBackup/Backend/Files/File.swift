//
//  FileOperations.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-06-21.
//

import Foundation

public class File: Identifiable {
    public let id: URL
    var name: String
    var created: Date
    var modified: Date

    
    init(url: URL) {
//        print("File.init()")
        if FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
//            print("File exists at \(url.path(percentEncoded: false))")
        } else {
//            print("File not found: \(url.path(percentEncoded: false))")
            exit(1)
        }
        
        self.id = url
        self.name = url.lastPathComponent
        self.created = try! url.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date()
        self.modified = try! url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? Date()
        
//        print("id: \(id)")
//        print("path: \(id.path(percentEncoded: false))")
//        print("name: \(name)")
//        print("created: \(created)")
//        print("modified: \(modified)")
    }
    
    func Exists() -> Bool {
        FileManager.default.fileExists(atPath: id.path)
    }
    
    func Delete() -> Bool {
        ((try? FileManager.default.removeItem(at: id)) != nil)
    }
    
    func CreatedDate() -> Date? {
        let resourceValues = try? id.resourceValues(forKeys: [.creationDateKey])
        if let date = resourceValues?.creationDate {
            print("File.CreatedDate: \(date)")
            self.created = date
            print("UPDATED")
        }
//        let inode = try? id.resourceValues(forKeys: [.fileIdentifierKey])
        return resourceValues?.creationDate
    }
    
    func ModifiedDate() -> Date? {
        let resourceValues = try? id.resourceValues(forKeys: [.contentModificationDateKey])
        if let date = resourceValues?.contentModificationDate {
            print("File.ModifiedDate: \(date)")
            self.modified = date
            print("UPDATED")
        }
        return resourceValues?.contentModificationDate
    }
}
