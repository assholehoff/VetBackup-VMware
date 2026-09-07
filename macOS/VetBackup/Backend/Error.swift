//
//  BackupResult.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-09-06.
//

protocol Result: Sendable {}

enum BackupResult: Result {
    case abort,
         fail,
         success,
         skip
}

enum VirtualMachineError: Error {
    enum component {
        case bundle,
             diskFile,
             vmxFile,
             key,
             user,
             passwd
    }
    case notFound(component),
         invalid(component),
         offline
}
