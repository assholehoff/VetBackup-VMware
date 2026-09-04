//
//  VirtualMachineTabView.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-08-30.
//

import SwiftUI
import UniformTypeIdentifiers

struct VirtualMachineTabView: View {
    @State var vmBundleURL: URL = AppSettings.shared.vmBundleURL
    @State var vmKey: String = AppSettings.shared.vmKey
    @State var vmUser: String = AppSettings.shared.vmUser
    @State var vmPasswd: String = AppSettings.shared.vmPasswd

    @State var isTargeted: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            VStack {
                Image(.PC)
                    .resizable()
                    .scaledToFit()
                    .padding([.top, .horizontal], 12)
                Text(
                    vmBundleURL
                        .deletingPathExtension()
                        .lastPathComponent
                        .removingPercentEncoding
                    ??
                    vmBundleURL
                        .deletingPathExtension()
                        .lastPathComponent
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                guard !providers.isEmpty, providers.count == 1 else { return false }
                for provider in providers {
                    provider.loadObject(ofClass: NSURL.self) { nsurl, error in
                        guard error == nil, let url = nsurl as? URL, url.pathExtension == "vmwarevm" else { return }
                        DispatchQueue.main.async { AppSettings.shared.vmBundleURL = url }
                    }
                }
                return true
            }
            Form {
                TextField(text: $vmKey, prompt: nil, label: { Image(systemName: "key.fill") })
                TextField(text: $vmUser, prompt: nil, label: { Image(systemName: "person.fill") })
                SecureField(text: $vmPasswd, prompt: nil, label: { Image(systemName: "lock.fill") })
            }
            .frame(maxWidth: 300, maxHeight: 200)
        }
    }
}
