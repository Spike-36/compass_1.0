//
//  FuzzyMatcher.swift
//  Compass
//
//  Lightweight fuzzy matching for pleadings
//

import Foundation

struct FuzzyMatcher {
    /// Known prefixes used in answers
    private static let prefixes: [String] = [
        "admitted that",
        "not admitted that",
        "not known and not admitted that"
    ]

    /// Normalize text: lowercase, strip hidden chars, collapse spaces
    private static func normalize(_ text: String) -> String {
        let lowered = text.lowercased()
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\u{00A0}", with: " ") // NBSP → space
            .replacingOccurrences(of: "\u{00AD}", with: "")  // soft hyphen → remove

        // collapse multiple spaces into one
        let collapsed = lowered.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )

        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Strip known prefixes like "admitted that"
    private static func stripPrefix(_ text: String) -> String {
        var result = text
        for prefix in prefixes {
            if result.hasPrefix(prefix) {
                result = result.replacingOccurrences(of: prefix, with: "")
                break
            }
        }
        return result.trimmingCharacters(in: .whitespaces)
    }

    /// Compute Levenshtein similarity ratio (0.0–1.0)
    private static func levenshteinSimilarity(_ lhs: String, _ rhs: String) -> Double {
        let lhsChars = Array(lhs)
        let rhsChars = Array(rhs)
        let m = lhsChars.count
        let n = rhsChars.count

        if m == 0 { return n == 0 ? 1.0 : 0.0 }
        if n == 0 { return 0.0 }

        var dist = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)

        for i in 0...m { dist[i][0] = i }
        for j in 0...n { dist[0][j] = j }

        for i in 1...m {
            for j in 1...n {
                let cost = lhsChars[i - 1] == rhsChars[j - 1] ? 0 : 1
                dist[i][j] = min(
                    dist[i - 1][j] + 1,       // deletion
                    dist[i][j - 1] + 1,       // insertion
                    dist[i - 1][j - 1] + cost // substitution
                )
            }
        }

        let distance = dist[m][n]
        let maxLen = max(m, n)
        return 1.0 - (Double(distance) / Double(maxLen))
    }

    /// Main fuzzy match check (hybrid model)
    static func isMatch(statement: String, answer: String, context: String = "general") -> Bool {
        let sNorm = normalize(statement)
        let aNorm = normalize(answer)

        // Also try without prefixes
        let sCore = stripPrefix(sNorm)
        let aCore = stripPrefix(aNorm)

        // Debug logging
        print("🔎 [\(context)] Checking match:")
        print("   Statement raw: '\(statement)'")
        print("   Answer raw:    '\(answer)'")
        print("   Statement norm: '\(sNorm)'")
        print("   Answer norm:    '\(aNorm)'")
        print("   Statement core: '\(sCore)'")
        print("   Answer core:    '\(aCore)'")

        // 1. Exact match after normalization
        if sNorm == aNorm || sCore == aCore {
            print("✅ [\(context)] Exact match")
            return true
        }

        // 2. Containment check
        if sNorm.contains(aCore) || aNorm.contains(sCore) {
            print("✅ [\(context)] Containment match")
            return true
        }

        // 3. Fuzzy similarity (fallback)
        let similarity = levenshteinSimilarity(sCore, aCore)
        print("   [\(context)] Similarity score: \(similarity)")
        if similarity >= 0.72 { // slightly more forgiving threshold
            print("✅ [\(context)] Fuzzy match (threshold passed)")
            return true
        }

        print("❌ [\(context)] No match")
        return false
    }

    /// Find best N matches for a given statement against candidate answers
    static func bestMatches(for statement: String, in answers: [String], topN: Int = 3) -> [(answer: String, score: Double)] {
        let sNorm = normalize(stripPrefix(statement))

        let scored = answers.map { a in
            let aNorm = normalize(stripPrefix(a))
            return (answer: a, score: levenshteinSimilarity(sNorm, aNorm))
        }

        return scored.sorted { $0.score > $1.score }.prefix(topN).map { $0 }
    }
}

//
//  Created by Peter Milligan on 15/09/2025.
//  Revised with bestMatches helper
//

