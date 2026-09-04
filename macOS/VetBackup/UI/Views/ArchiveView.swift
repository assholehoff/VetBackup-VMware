//
//  ArchiveView.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-08-27.
//

import SwiftUI

struct ArchiveView: View {
    @State private var files: [BackupFile] = []
    @State private var selectedFiles = Set<BackupFile.ID>()
    @State private var sortColumn: SortColumn = .date
    @State private var sortAscending: Bool = true

    enum SortColumn {
        case date, name, size
    }

    var body: some View {
        ZStack {
            VStack {
                List(selection: $selectedFiles) {
                    // Header row:
                    HStack(alignment: .firstTextBaseline) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Name")
                            Spacer()
                            if sortColumn == .name {
                                if sortAscending {
                                    Image(systemName: "arrowtriangle.up.fill")
                                } else {
                                    Image(systemName: "arrowtriangle.down.fill")
                                }
                            }
                        }
                        .contentShape(.rect)
                        .frame(width: 196, alignment: .leading)
                        .background()
                        .backgroundStyle(.windowBackground)
                        .onTapGesture {
                            toggleSort(.name)
                        }
                        Divider()
                        HStack(alignment: .firstTextBaseline) {
                            Text("Date")
                            Spacer()
                            Spacer()
                            if sortColumn == .date {
                                if sortAscending {
                                    Image(systemName: "arrowtriangle.up.fill")
                                } else {
                                    Image(systemName: "arrowtriangle.down.fill")
                                }
                            }
                        }
                        .contentShape(.rect)
                        .frame(width: 196, alignment: .leading)
                        .background()
                        .backgroundStyle(.windowBackground)
                        .onTapGesture {
                            toggleSort(.date)
                        }
                        Divider()
                        HStack {
                            Text("Size")
                            Spacer()
                            if sortColumn == .size {
                                if sortAscending {
                                    Image(systemName: "arrowtriangle.up.fill")
                                } else {
                                    Image(systemName: "arrowtriangle.down.fill")
                                }
                            }
                        }
                        .contentShape(.rect)
                        .frame(width: 64, alignment: .leading)
                        .background()
                        .backgroundStyle(.windowBackground)
                        .onTapGesture {
                            toggleSort(.size)
                        }
                        Divider()
                        Text("\(Image(systemName: "cloud.fill"))")
                            .contentShape(.rect)
                            .frame(width: 16)
                            .background()
                            .backgroundStyle(.windowBackground)
                        Divider()
                        Text("\(Image(systemName: "server.rack"))")
                            .contentShape(.rect)
                            .frame(width: 16)
                            .background()
                            .backgroundStyle(.windowBackground)
                    }
                    // Data:
                    ForEach(files) { file in
                        FileRowView(file: file)
                    }
                }
                .listStyle(.plain)
                Text("\(files.count) files")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding([.horizontal, .bottom], 8)
        }
        .onAppear { AppUIState.shared.showingArchiveWindow = true }
        .onDisappear { AppUIState.shared.showingArchiveWindow = false }
        .onChange(of: sortColumn) {
            files = files.sorted(by: sortFile(a:b:))
        }
        .onChange(of: sortAscending) {
            files = files.sorted(by: sortFile(a:b:))
        }
        .onReceive(AppSettings.shared.bf.folder!.$files) { newValue in
            files = newValue.sorted(by: sortFile(a:b:))
        }
    }

    private func sortFile(a: BackupFile, b: BackupFile) -> Bool {
        let result: Bool
        switch sortColumn {
        case .date:
            result = a.date < b.date
        case .name:
            result = a.name < b.name
        case .size:
            result = a.size < b.size
        }
        return sortAscending ? result : !result
    }

    private func toggleSort(_ column: SortColumn) {
        if sortColumn == column {
            sortAscending.toggle()
            print("sorting by \(sortColumn) in \(sortAscending ? "ascendling" : "descending") order")
        } else {
            sortColumn = column
            sortAscending = true
            print("sorting by \(sortColumn) in \(sortAscending ? "ascendling" : "descending") order")
        }
    }
}
