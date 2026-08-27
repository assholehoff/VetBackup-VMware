//
//  BackupView.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2025-12-08.
//

import SwiftUI
import System

struct BackupView: View {
    @Environment(\.openSettings) private var openSettings
    @EnvironmentObject private var vmp: VMProvider
    @EnvironmentObject private var bfp: BFProvider
    
    @State private var selectedFiles = Set<BackupFile.ID>()
    
    var body: some View {
        if let bf = bfp.bf {
            @ObservedObject var folder: BackupFolder = bf
            ZStack {
                VStack {
                    Table(folder.files, selection: $selectedFiles) {
                        TableColumn("File", value: \.name)
                            .width(min: 196, ideal: 288)
                        TableColumn("Date") { file in
                            Text(file.date.formatted(date: .long, time: .shortened))
                        }
                        .width(min: 196, ideal: 288)
                        TableColumn("Size") { file in
                            Text(file.Size())
                        }
                        .width(min: 64, ideal: 96, max: 128)
                        TableColumn("\(Image(systemName: "cloud.fill"))") { file in
                            if file.iCloudUploaded {
                                Text("\(Image(systemName: "checkmark.circle.fill"))").foregroundStyle(.green)
                            } else if file.iCloudIsUploading {
                                Text("\(Image(systemName: "arrowshape.up.circle.fill"))").foregroundStyle(.yellow)
                            } else {
                                Text("\(Image(systemName: "multiply.circle.fill"))").foregroundStyle(.secondary)
                            }
                        }
                            .width(16)
                        TableColumn("\(Image(systemName: "server.rack"))") { file in
                            Text("\(Image(systemName: "multiply.circle.fill"))").foregroundStyle(.secondary)
                        }
                            .width(16)
                    }
//                    if selectedFiles.count > 0 {
//                        Text("There are \(folder.files.count) files in \(vmp.vm?.Path() ?? ""), \(selectedFiles.count) selected")
//                    } else {
//                        Text("There are \(folder.files.count) files in \(vmp.vm?.Path() ?? "")")
//                    }
                }
            }
        } else {
            LoadingView()
        }
    }
}
