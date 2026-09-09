//
//  Functions.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-08-28.
//

import Foundation

/**
 * The URL with `Contents/Public/vmrun` appended to its path
 */
func createVmrunURL(fromApp url: URL) -> URL {
    url
        .appending(path: "Contents")
        .appending(path: "Public")
        .appending(path: "vmrun")
}
/**
 * `lastPathComponent` with any percent encoding removed.
 */
func lastPathString(_ url: URL) -> String {
    if let str = url.lastPathComponent.removingPercentEncoding { return str }
    return url.lastPathComponent
}

/**
 * The URL found in supplied `NSNotification`, or `nil`.
 */
func nsnotificationToURL(_ notification: NSNotification) -> URL? {
    if let potentialInfo = notification.userInfo {
        let info = potentialInfo as [AnyHashable: Any]
        if let url = info["NSWorkspaceVolumeURLKey"] as? URL {
            return url
        }
    }
    return nil
}

/**
 * A Swift `URL` from an ObjC `NSURL`, or `nil`.
 */
func urlFrom(nsurl: NSURL) -> URL? {
    guard let nsstring = nsurl.absoluteString else {
        return nil
    }
    if let url = URL(string: nsstring) {
        return url
    }
    return nil
}
