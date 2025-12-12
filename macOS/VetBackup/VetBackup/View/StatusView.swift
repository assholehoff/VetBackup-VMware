//
//  StatusView.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2025-12-06.
//

import SwiftUI
import UserNotifications

struct StatusView: View {
    @Environment(\.openSettings) private var openSettings
    @ObservedObject var folder: BackupFolder
    
    @State var doingBackup: Bool = false
    @State var backupStatus: String = ""
    @State var lastBackup: String = "No backup found"
    
    @State private var authenticated: Bool = false
    @State private var VMXPath: String = ""
    @State private var VMUser: String = ""
    @State private var VMKey: String = ""
    @State private var VMPasswd: String = ""
    
    var body: some View {
        VStack {
            if authenticated {
                Image(.logotype)
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                    .padding(.bottom)
                if lastBackup != "No backup found" {
                    Text("Last backup done")
                    Text(lastBackup)
                        .padding(.bottom)
                } else {
                    Text("No backup found")
                }
                if doingBackup {
                    ProgressView(backupStatus)
                        .progressViewStyle(.circular)
                        .padding(.bottom)
                } else {
                    Button(action: {
                        doBackup()
                    }, label: {
                        Text("Backup now")
                    })
                }
            } else {
                // present Settings window
                Button(action: {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    openSettings()
                }, label: {
                    Text("Open Settings")
                })
            }
        }
        .onAppear {
            lastBackup = folder.files.first?.date.formatted(date: .complete, time: .shortened) ?? "No backup found"
            if let data = try? KeychainInterface.shared.readPassword(service: "com.ad.vetbackup", account: "VMXPath"), let path = String(data: data, encoding: .utf8) {
                VMXPath = path
            }
            if let data = try? KeychainInterface.shared.readPassword(service: "com.ad.vetbackup", account: "VMUser"), let user = String(data: data, encoding: .utf8) {
                VMUser = user
            }
            if let data = try? KeychainInterface.shared.readPassword(service: "com.ad.vetbackup", account: "VMKey"), let key = String(data: data, encoding: .utf8) {
                VMKey = key
            }
            if let data = try? KeychainInterface.shared.readPassword(service: "com.ad.vetbackup", account: "VMPasswd"), let passwd = String(data: data, encoding: .utf8) {
                VMPasswd = passwd
            }
            if allSet() {
                // TODO verify these work with vmrun and prompt if not
                authenticated = true
            }
        }
        .padding()
    }
    
    private func allSet() -> Bool {
        if VMXPath != "" && VMUser != "" && VMKey != "" && VMPasswd != "" {
            return true
        }
        return false
    }
    
    private func doBackup() {
        backupStatus = String(localized: "Backing up")
        doingBackup = true
        
        let vm = VirtualMachine(VMXPath: VMXPath, VMKey: VMKey, VMUser: VMUser, VMPasswd: VMPasswd)
        
        DispatchQueue.main.async(execute: {
            let content = UNMutableNotificationContent()
            content.title = String(localized: "Backup in progress")
            content.subtitle = String(localized: "Vetvision will close in Windows if open")
            content.sound = UNNotificationSound.default

            let uuid = UUID().uuidString
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: uuid, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)

            if !vm.Backup() {
                if !vm.IsRunning() {
                    print("vm is off")
                    // TODO update View to reflect the off state and prompt user to start vm
                    let errorContent = UNMutableNotificationContent()
                    errorContent.title = String(localized: "Backup failed")
                    errorContent.subtitle = String(localized: "Make sure Windows is running and user is logged in")
                    let errorTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                    let errorRequest = UNNotificationRequest(identifier: UUID().uuidString, content: errorContent, trigger: errorTrigger)
                    UNUserNotificationCenter.current().add(errorRequest)
                } else {
                    print("error: vm appears to be running, but backup failed")
                    // TODO check if user is logged into Windows and prompt if not
                }
            } else {
                print("true")
            }
            doingBackup = false
            
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [uuid])
        })
    }
}

#Preview {
//    let backupFolderURL = URL(filePath: "/Volumes/MP600/Downloads", directoryHint: .isDirectory)
//    StatusView(folder: BackupFolder(url: backupFolderURL))
//    StatusView()
}
