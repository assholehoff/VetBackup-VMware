//
//  Error.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-09-06.
//

protocol Result: Sendable {}

enum BackupResult: Result {
    // TODO: implement this for VirtualMachine
    case abort,
         fail,
         skip,
         success
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
