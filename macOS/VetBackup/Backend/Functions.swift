//
//  Functions.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-08-28.
//

import Foundation

/**
 * URL.lastPathComponent.removingPercentEncoding ?? URL.lastPathComponent
 */
func lastPathString(_ url: URL) -> String {
    if let str = url.lastPathComponent.removingPercentEncoding { return str }
    return url.lastPathComponent
}

func nsnotificationToURL(_ notification: NSNotification) -> URL? {
    if let potentialInfo = notification.userInfo {
        let info = potentialInfo as [AnyHashable: Any]
        if let url = info["NSWorkspaceVolumeURLKey"] as? URL {
            return url
        }
    }
    return nil
}

func urlFrom(nsurl: NSURL) -> URL? {
    guard let nsstring = nsurl.absoluteString else {
        return nil
    }
    if let url = URL(string: nsstring) {
        return url
    }
    return nil
}
