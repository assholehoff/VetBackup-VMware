//
//  Time.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-05-27.
//

import Foundation

func timeStamp() -> String {
    Date().formatted(date: .omitted, time: .standard) + ":"
}

/**
 * Returns a Date set today at the time taken from the input parameter Date.
 */
func today(at time: Date) -> Date {
    let c = Calendar.current
    let t = c.dateComponents([.hour, .minute], from: time)
    var d = c.dateComponents([.day, .month, .year], from: .now)
    d.hour = t.hour
    d.minute = t.minute
    let next = c.date(from: d)!
    return next
}

/**
 * Returns a Date set tomorrow at the time taken from the input parameter Date.
 */
func tomorrow(at time: Date) -> Date {
    return today(at: time).addingTimeInterval(24.0 * 60.0 * 60.0)
}

/**
 * Next returns a Date for the next future occurance
 * of the point in time taken from the parameter "time" of type Date,
 * either today or tomorrow
 */
func next(time: Date) -> Date {
    let n = today(at: time)
    if n < Date.now {
        return tomorrow(at: time)
    } else {
        return n
    }
}
