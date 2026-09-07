//
//  Log.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-09-07.
//

import Foundation

class Log {
    var book: [LogEntry] = []

    static let app = Log()
    static let backup = Log()

    func enter(message: String) {
        book.append(
            LogEntry(
                id: UUID(),
                date: .now,
                message: message,
                subject: nil,
                result: nil
            )
        )
    }

    func delete(entry id: UUID) {
        // TODO: delete entry from log
    }

    func load(url: URL) {
        // TODO: load log entries from file
    }

    func save(url: URL) {
        // TODO: save log entries to file
    }
}
