//
//  UTType.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2025-12-07.
//

import Foundation
import UniformTypeIdentifiers

extension UTType {
    public static let VMBundle: UTType = UTType(exportedAs: "com.vmware.vm-package", conformingTo: .bundle)
    public static let VMConfig: UTType = UTType(exportedAs: "com.vmware.vm-config", conformingTo: .utf8PlainText)
}
