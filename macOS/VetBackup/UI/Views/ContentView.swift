//
//  ContentView.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-08-27.
//

import SwiftUI

struct ContentView: View {
    @State var isReady: Bool

    init() {
        self.isReady = AppSettings.shared.vmIsReady
    }

    var body: some View {
        ZStack {
            if self.isReady {
                StatusView()
            } else {
                SetupView()
            }
        }
        .onReceive(AppSettings.shared.$vmIsReady) { newValue in
            self.isReady = newValue
        }
    }
}

#Preview {
    ContentView()
}
