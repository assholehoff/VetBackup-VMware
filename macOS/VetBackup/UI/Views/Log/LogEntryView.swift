//
//  LogEntryView.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-09-07.
//

import SwiftUI

struct LogEntryView: View {
    let entry: LogEntry

    var body: some View {
        VStack {
            Text(entry.date.formatted(date: .abbreviated, time: .complete))
            Text(entry.message).multilineTextAlignment(.leading)
        }
        .padding(.vertical, 4)
    }
}
