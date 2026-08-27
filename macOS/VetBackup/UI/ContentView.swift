//
//  ContentView.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2025-11-28.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow
    
    @EnvironmentObject private var vmp: VMProvider
    @EnvironmentObject private var bfp: BFProvider
    
    var body: some View {
        if let vm = vmp.vm, let bf = bfp.bf {
            StatusView()
                .environmentObject(vm)
                .environmentObject(bf)
//            ZStack {
//                Button(action: {
//                    NSApplication.shared.activate(ignoringOtherApps: true)
//                    openSettings()
//                }, label: {
//                    Image(systemName: "gear")
//                })
//                .buttonBorderShape(.circle)
//                .padding(.top)
//                .padding(.trailing, 32)
//                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
//
//                Button(action: {
//                    NSApplication.shared.activate(ignoringOtherApps: true)
//                    openWindow(id: "backupWindow")
//                }, label: {
//                    Image(systemName: "arrow.counterclockwise.circle")
//                })
//                .buttonBorderShape(.circle)
//                .padding()
//                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
//
//                StatusView()
//                    .environmentObject(vm)
//                    .environmentObject(bf)
//            }
        } else {
            LoadingView()
        }
    }
}
