//
//  Time.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-05-27.
//

import Foundation

/** Convenient when printing to stdout */
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

func lastNthMonth(_ n: Int) -> Date? {
    Calendar.current.date(byAdding: .month, value: n, to: .now)
}

func sameNotNil(a: Int?, b: Int?) -> Bool {
    guard a != nil, b != nil, a == b else { return false }
    return true
}

func sameDay(a aDate: Date, b bDate: Date) -> Bool {
    let calendarComponents: Set<Calendar.Component> = [
        .year, .month, .day, .hour, .minute, .second
    ]
    let a = Calendar.current.dateComponents(calendarComponents, from: aDate)
    let b = Calendar.current.dateComponents(calendarComponents, from: bDate)

    guard sameNotNil(a: a.day, b: b.day),
          sameNotNil(a: a.month, b: b.month),
          sameNotNil(a: a.year, b: b.year)
    else { return false }

    return true
}

func sameDay(dates: [Date]) -> Bool {
    guard !dates.isEmpty, let a = dates.first else { return false }
    let calendarComponents: Set<Calendar.Component> = [
        .year, .month, .day, .hour, .minute, .second
    ]

    for b in dates {
        guard sameDay(a: a, b: b) else { return false }
    }

    return true
}

func sameMonth(a aDate: Date, b bDate: Date) -> Bool {
    let calendarComponents: Set<Calendar.Component> = [
        .year, .month, .day, .hour, .minute, .second
    ]
    let a = Calendar.current.dateComponents(calendarComponents, from: aDate)
    let b = Calendar.current.dateComponents(calendarComponents, from: bDate)

    guard sameNotNil(a: a.month, b: b.month),
          sameNotNil(a: a.year, b: b.year)
    else { return false }

    return true
}

func sameMonth(dates: [Date]) -> Bool {
    guard !dates.isEmpty, let a = dates.first else { return false }
    let calendarComponents: Set<Calendar.Component> = [
        .year, .month, .day, .hour, .minute, .second
    ]

    for b in dates {
        guard sameMonth(a: a, b: b) else { return false }
    }

    return true
}

func sameYear(a aDate: Date, b bDate: Date) -> Bool {
    let calendarComponents: Set<Calendar.Component> = [
        .year, .month, .day, .hour, .minute, .second
    ]
    let a = Calendar.current.dateComponents(calendarComponents, from: aDate)
    let b = Calendar.current.dateComponents(calendarComponents, from: bDate)

    guard sameNotNil(a: a.year, b: b.year) else { return false }

    return true
}

func sameYear(dates: [Date]) -> Bool {
    guard !dates.isEmpty, let a = dates.first else { return false }
    let calendarComponents: Set<Calendar.Component> = [
        .year, .month, .day, .hour, .minute, .second
    ]

    for b in dates {
        guard sameYear(a: a, b: b) else { return false }
    }

    return true
}
