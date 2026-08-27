//
//  LaunchView.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-08-03.
//

import SwiftUI

struct SetupView: View {
    @EnvironmentObject var vmp: VMProvider
    @EnvironmentObject var bfp: BFProvider
    
    var body: some View {
        ZStack {
            Text("No configuration found. Please configure a VM and a backup folder.")
        }
    }
}
