//
//  VM.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2025-12-04.
//

import Foundation

public struct VirtualMachine {
    let VMXPath: String // UserSettings
    var VMKey: String // Keychain
    var VMUser: String // UserSettings
    var VMPasswd: String // Keychain
    
    let VMRunPath: String = "/Applications/VMware Fusion.app/Contents/Public/vmrun"
    
    var WinProgram: String = "C:\\Program Files\\VetBackup\\VetBackup.exe"
    var WinArguments: String = "C:\\VetVision\\VETDB\\Database.fdb"
    
    public init() {
        self.init(VMXPath: "", VMKey: "", VMUser: "", VMPasswd: "")
    }
    
    public init(VMXPath: String) {
        self.init(VMXPath: VMXPath, VMKey: "", VMUser: "", VMPasswd: "")
    }
    
    public init(VMXPath: String, VMKey: String, VMUser: String, VMPasswd: String) {
        self.VMXPath = VMXPath
        self.VMKey = VMKey
        self.VMUser = VMUser
        self.VMPasswd = VMPasswd
    }
    
    public mutating func SetKey(key: String) {
        self.VMKey = key
    }
    
    public mutating func SetUser(user: String) {
        self.VMUser = user
    }
    
    public mutating func SetPassword(password: String) {
        self.VMPasswd = password
    }
    
    public mutating func SetWinProgram(path: String) {
        self.WinProgram = path
    }
    
    public mutating func SetWinArguments(path: String) {
        self.WinArguments = path
    }
    
    public func Backup() -> Bool {
        let off: String = "Error: The virtual machine is not powered on: \(VMXPath)\n"
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.standardInput = nil
        task.executableURL = URL(fileURLWithPath: VMRunPath)
        task.arguments = ["-T", "fusion", "-vp", VMKey, "-gu", VMUser, "-gp", VMPasswd, "runProgramInGuest", VMXPath, "-activeWindow", "-interactive", WinProgram, WinArguments]
        
        do {
            try task.run()
            let data = try pipe.fileHandleForReading.readToEnd()
            let output = String(data: data ?? Data(), encoding: .utf8)
            if output != "" && output != off {
                print(output!)
            }
            if output == off {
                return false
            }
        } catch {
            print("error: \(error)")
            return false
        }
        return true
    }
    
    public func IsRunning() -> Bool {
        let task = Process()
        let pipe = Pipe()
        var running = false
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.standardInput = nil
        task.executableURL = URL(fileURLWithPath: VMRunPath)
        task.arguments = ["-T", "fusion", "list"]
        
        do {
            try task.run()
            let data = try pipe.fileHandleForReading.readToEnd()
            let output = String(data: data ?? Data(), encoding: .utf8)
            if output == "Total running VMs: 0" {
                return running
            }
            output?.enumerateLines { (line, _) in
                if line == VMXPath {
                    running = true
                }
            }
        } catch {
            print("error: \(error)")
        }
        return running
    }
    
    private func vmrunString() -> String {
        return "\(VMRunPath) -T fusion -vp '\(self.VMKey)' -gu '\(self.VMUser)' -gp '\(self.VMPasswd)' runProgramInGuest '\(VMXPath)' '\(WinProgram)' '\(WinArguments)'"
    }
}
