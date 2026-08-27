//
//  Scheduler.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-05-27.
//

import Foundation

/**
 * Returns a Date set today at the time taken from the input parameter Date.
 */
func Today(at time: Date) -> Date {
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
func Tomorrow(at time: Date) -> Date {
    return Today(at: time).addingTimeInterval(24.0 * 60.0 * 60.0)
}

/**
 * Next returns a Date for the next future occurance
 * of the point in time taken from the parameter "time" of type Date,
 * either today or tomorrow
 */
func Next(time: Date) -> Date {
    let n = Today(at: time)
    if n < Date.now {
        return Tomorrow(at: time)
    } else {
        return n
    }
}
