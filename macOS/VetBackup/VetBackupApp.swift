//
//  VetBackupApp.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2025-11-28.
//

import SwiftUI

@main
struct VetBackupApp: App {
    var body: some Scene {
        MenuBarExtra("VetBackup", systemImage: "hare.fill"){
            ContentView().frame(width: 400)
        }.menuBarExtraStyle(.window)
    }
}
