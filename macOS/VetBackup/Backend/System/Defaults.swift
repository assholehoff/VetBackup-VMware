//
//  Defaults.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-08-27.
//

import Foundation

func defaultDate() -> Date {
    var components = DateComponents()
    components.year = 1958
    components.month = 6
    components.day = 13
    components.hour = 20
    components.minute = 00
    components.second = 00

    return Calendar.current.date(from: components)!
}

func registerUserDefaults() {
    UserDefaults.standard.register(defaults: [
        // NOTE: Paths internal to Windows in the Virtual Machine:
        "VM: cmd.exe path" : "C:\\Windows\\System32\\cmd.exe",
        "VM: pwsh.exe path" : "C:\\Program Files\\PowerShell\\7\\pwsh.exe",
        "VM: BackupDatabase.exe path" : "C:\\Program Files\\VetBackup\\BackupDatabase.exe",
        "VM: LastModifiedDate.exe path" : "C:\\Program Files\\VetBackup\\LastModifiedDate.exe",
        "VM: LastModifiedDate output file path" : "V:\\.LastModifiedDate",
        "VM: Database.fdb path" : "C:\\VetVision\\VETDB\\Database.fdb"
    ])
}
