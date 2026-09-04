//
//  Regex.swift
//  VetBackup
//
//  Created by Anton Dahlén on 2026-08-27.
//

import Foundation

func getDate(from name: String) -> Date {
    getDate(from: name, format: "yyyyMMdd-HHmmss")
}

func getDate(from name: String, format: String) -> Date {
    let df = DateFormatter()
    df.dateFormat = format
    return df.date(from: name.replacingOccurrences(of: "DVS-", with: "")
        .replacingOccurrences(of: ".zip", with: "")) ?? Date(timeIntervalSince1970: 0)
}

/**
 * Escape the characters `.^$*+?()[]{}\|` in String.
 */
func escapeRegexChars(in str: String) -> String {
    // replace all of: .^$*+?()[]{}\|
    var string: String = str
    string = string.replacingOccurrences(of: "\\", with: "\\\\")
    string = string.replacingOccurrences(of: ".", with: "\\.")
    string = string.replacingOccurrences(of: "^", with: "\\^")
    string = string.replacingOccurrences(of: "$", with: "\\$")
    string = string.replacingOccurrences(of: "*", with: "\\*")
    string = string.replacingOccurrences(of: "+", with: "\\+")
    string = string.replacingOccurrences(of: "?", with: "\\?")
    string = string.replacingOccurrences(of: "(", with: "\\(")
    string = string.replacingOccurrences(of: ")", with: "\\)")
    string = string.replacingOccurrences(of: "[", with: "\\[")
    string = string.replacingOccurrences(of: "]", with: "\\]")
    string = string.replacingOccurrences(of: "{", with: "\\{")
    string = string.replacingOccurrences(of: "}", with: "\\}")
    string = string.replacingOccurrences(of: "|", with: "\\|")
    return string
}

func createDateRegexStringFor(format: String) -> String {
    var string: String = format
    string = string.replacingOccurrences(of: "yyyy", with: "\\d{4}")
    string = string.replacingOccurrences(of: "MM", with: "[0-1]{1}[0-9]{1}")
    string = string.replacingOccurrences(of: "dd", with: "[0-3]{1}[0-9]{1}")
    string = string.replacingOccurrences(of: "HH", with: "[0-2]{1}[0-9]{1}")
    string = string.replacingOccurrences(of: "mm", with: "[0-5]{1}[0-9]{1}")
    string = string.replacingOccurrences(of: "ss", with: "[0-5]{1}[0-9]{1}")
    return string
}

func createDateRegex(format: String, prefix: String, suffix: String) -> Regex<AnyRegexOutput> {
    let dateString: String = createDateRegexStringFor(format: escapeRegexChars(in: format))
    let prefixString: String = escapeRegexChars(in: prefix)
    let suffixString: String = escapeRegexChars(in: suffix)
    guard let regex = try? Regex(prefixString + dateString + suffixString) else { return try! Regex("DVS-\\d{8}-\\d{6}\\.zip") }
    print(prefixString+dateString+suffixString)
    return regex
}
