//
//  LogView.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-09-07.
//

import SwiftUI

struct LogView: View {
    @State var selectedTab = 0
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("App", systemImage: "macbook", value: 0) {
                LogTabView(log: Log.app)
            }
            Tab("Backup", systemImage: "archivebox", value: 1) {
                LogTabView(log: Log.backup)
            }
        }
    }
}
