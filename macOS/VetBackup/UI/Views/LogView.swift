//
//  LogView.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-09-09.
//

import AppKit
import SwiftUI

struct LogView: View {
    var logs: LogStore
    @State private var exportIsPresented: Bool = false

    var body: some View {
        Form {
            Section(header: Text("debug")) {
                Button("exportLogs") {
                    logs.export()
                    exportIsPresented = true
                }
                .sheet(isPresented: $exportIsPresented) {
                    EmptyView()
                }
            }
        }
    }
}
