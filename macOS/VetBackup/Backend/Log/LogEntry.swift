//
//  LogEntry.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-09-07.
//

import Foundation

struct LogEntry: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let date: Date
    let message: String

    let subject: String? // TODO: create enum for these
    let result: String?  //

    func print() {
        Swift.print("\(timeStamp()) LogEntry")
        Swift.print("\t.id: \(id.uuidString)")
        Swift.print("\t.date: \(date.formatted(date: .omitted, time: .standard))")
        Swift.print("\t.message: \(message)")
    }
}
