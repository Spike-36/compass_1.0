import Foundation

public enum Slug {
    /// Lowercase; replace non-alnum with '-', collapse repeats, trim '-'
    public static func slugify(_ filename: String) -> String {
        let base = (filename as NSString).deletingPathExtension
        let lower = base.lowercased()
        let mapped = lower.map { ch -> Character in
            (ch.isLetter || ch.isNumber) ? ch : "-"
        }
        var s = String(mapped)
        while s.contains("--") { s = s.replacingOccurrences(of: "--", with: "-") }
        s = s.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return s.isEmpty ? "document" : s
    }
}
//
//  Slug.swift
//  Compass
//
//  Created by Peter Milligan on 12/09/2025.
//

