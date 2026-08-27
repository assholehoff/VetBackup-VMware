//
//  URL.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2025-12-07.
//

import Foundation

extension URL: @retroactive Identifiable {
    public var id: String { return lastPathComponent }
}
