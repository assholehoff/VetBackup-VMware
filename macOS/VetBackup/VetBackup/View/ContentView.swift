//
//  ContentView.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2025-11-28.
//

import SwiftUI

struct ContentView: View {
//    @AppStorage("BackupFolderURL") private var BackupFolderURL: URL =
//        .documentsDirectory.appending(path: "VetVision", directoryHint: .isDirectory)
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow
    @ObservedObject var folder: BackupFolder
    
    var body: some View {
        ZStack {
            Button(action: {
                NSApplication.shared.activate(ignoringOtherApps: true)
                openSettings()
            }, label: {
                Image(systemName: "gear")
            })
            .buttonBorderShape(.circle)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            Button(action: {
                NSApplication.shared.activate(ignoringOtherApps: true)
                openWindow(id: "backupWindow")
            }, label: {
                Image(systemName: "arrow.counterclockwise.circle")
            })
            .buttonBorderShape(.circle)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            StatusView(folder: folder)
//            StatusView()
        }
    }
}

#Preview {
//    let backupFolderURL = URL(filePath: "/Volumes/MP600/Downloads", directoryHint: .isDirectory)
//    ContentView(folder: BackupFolder(url: backupFolderURL))
//    ContentView()
}
