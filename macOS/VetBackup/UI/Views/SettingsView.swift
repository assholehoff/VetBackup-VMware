//
//  SettingsView.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-08-27.
//

import SwiftUI

struct SettingsView: View {
    @State var selectedTab: Int = 0

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                Tab("General", systemImage: "gear", value: 0) { GeneralTabView() }
                Tab("Virtual Machine", systemImage: "pc", value: 1) { VirtualMachineTabView() }
//                Tab("Local Network", systemImage: "server.rack", value: 2) { LocalNetworkTabView() }
//                Tab("Internet", systemImage: "network", value: 3) { InternetTabView() }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
        .onAppear { AppUIState.shared.showingSettingsWindow = true }
        .onDisappear { AppUIState.shared.showingSettingsWindow = false }
    }
}
