//
//  Log.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-09-08.
//

import OSLog

class Log {
    static let app = Logger(subsystem: "com.ad.vetbackup", category: "app") // UI stuff
    static let backend = Logger(subsystem: "com.ad.vetbackup", category: "backend") // not UI stuff
    static let backup = Logger(subsystem: "com.ad.vetbackup", category: "backup") // results from backup attempts
}
