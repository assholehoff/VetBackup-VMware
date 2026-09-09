//
//  Log.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-09-08.
//

import Foundation
import OSLog

class Log {
    static let app = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "app"
    )
    static let backend = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "backend"
    )
    static let backup = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "backup"
    )
}

@MainActor @Observable final class LogStore {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: LogStore.self)
    )

    private(set) var entries: [String] = []

    func export() {
        do {
            let store = try OSLogStore(scope: .currentProcessIdentifier)
            let position = store.position(timeIntervalSinceLatestBoot: 1)

            entries = try store
                .getEntries(at: position)
                .compactMap { $0 as? OSLogEntryLog }
                .filter { $0.subsystem == Bundle.main.bundleIdentifier! }
                .map { "[\($0.date.formatted())] [\($0.category)] \($0.composedMessage)" }
        } catch {
            Self.logger.warning("\(error.localizedDescription, privacy: .public)")
        }
    }
}
