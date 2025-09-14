import Foundation

public enum SentenceSplitter {

    /// Splits a paragraph into sentences using regex heuristics.
    /// Rules:
    /// - Split on `.?!` only when followed by space + capital letter.
    /// - Don’t split inside common abbreviations (Mr., Dr., No., etc).
    /// - Trims whitespace/newlines from each sentence.
    public static func split(_ paragraph: String) -> [String] {
        let abbreviations = ["Mr.", "Mrs.", "Dr.", "No.", "Prof.", "Sr.", "Jr."]
        let pattern = #"(?<=[.?!])\s+(?=[A-Z])"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            // fallback: old naive splitter
            return naiveSplit(paragraph)
        }

        // Use regex to split paragraph into candidate sentences
        let nsrange = NSRange(paragraph.startIndex..<paragraph.endIndex, in: paragraph)
        let matches = regex.matches(in: paragraph, range: nsrange)

        var sentences: [String] = []
        var lastIndex = paragraph.startIndex

        for match in matches {
            if let range = Range(match.range, in: paragraph) {
                let sentence = String(paragraph[lastIndex..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !sentence.isEmpty { sentences.append(sentence) }
                lastIndex = range.upperBound
            }
        }

        // tail
        let tail = String(paragraph[lastIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
        if !tail.isEmpty { sentences.append(tail) }

        // Post-filter: merge back if we split inside an abbreviation
        var merged: [String] = []
        for s in sentences {
            if let last = merged.last, abbreviations.contains(where: { last.hasSuffix($0) }) {
                merged[merged.count - 1] = last + " " + s
            } else {
                merged.append(s)
            }
        }

        return merged
    }

    private static func naiveSplit(_ paragraph: String) -> [String] {
        var parts: [String] = []
        var cur = ""

        for ch in paragraph {
            cur.append(ch)
            if ch == "." || ch == "!" || ch == "?" {
                let t = cur.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty { parts.append(t) }
                cur.removeAll(keepingCapacity: true)
            }
        }

        let tail = cur.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tail.isEmpty { parts.append(tail) }

        return parts
    }
}

