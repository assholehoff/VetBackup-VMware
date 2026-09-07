//
//  LogTabView.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-09-07.
//

import SwiftUI

struct LogTabView: View {
    var log: Log
    var body: some View {
        List(log.book) { entry in
            LogEntryView(entry: entry)
        }
    }
}
