//
//  FileRowView.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-09-03.
//

import SwiftUI

struct FileRowView: View {
    @ObservedObject var file: BackupFile
    @State var fileSizeString: String = ""

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(file.name).frame(width: 206, alignment: .leading)
            Text(file.date.formatted(date: .long, time: .shortened)).frame(width: 206, alignment: .leading)
            Text(file.sizeString()).frame(width: 70, alignment: .leading)
            if file.iCloudIsUploaded {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green).frame(width: 20)
            } else if file.iCloudIsUploading {
                Image(systemName: "arrowshape.up.circle.fill")
                    .foregroundStyle(.yellow).frame(width: 20)
            } else {
                Image(systemName: "multiply.circle.fill")
                    .foregroundStyle(.secondary).frame(width: 20)
            }
        }
        .onAppear { file.startMonitoring() }
        .onDisappear { file.stopMonitoring() }
        .onReceive(file.$size) { _ in
            fileSizeString = file.sizeString()
        }
    }
}
