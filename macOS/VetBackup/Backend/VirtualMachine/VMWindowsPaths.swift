//
//  VMWindowsPaths.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-08-28.
//

import Foundation

struct VMWindowsPaths {
    let cmdDotExe: String
    let pwshDotExe: String
    let backupDatabaseDotExe: String
    let databaseDotFdb: String
    let lastModifiedDotExe: String
    let lastModifiedOutput: String

    init(
        cmdExe: String,
        pwshExe: String,
        backupExe: String,
        database: String,
        modifiedExe: String,
        modifiedOut: String,
    ) {
        self.cmdDotExe = cmdExe
        self.pwshDotExe = pwshExe
        self.backupDatabaseDotExe = backupExe
        self.databaseDotFdb = database
        self.lastModifiedDotExe = modifiedExe
        self.lastModifiedOutput = modifiedOut
    }

    static let defaults: VMWindowsPaths = VMWindowsPaths(
        cmdExe: "C:\\Windows\\System32\\cmd.exe",
        pwshExe: "C:\\Program Files\\PowerShell\\7\\pwsh.exe",
        backupExe: "C:\\Program Files\\VetBackup\\BackupDatabase.exe",
        database: "C:\\VetVision\\VETDB\\Database.fdb",
        modifiedExe: "C:\\Program Files\\VetBackup\\LastModifiedDate.exe",
        modifiedOut: "V:\\.LastModifiedDate"
    )
}
