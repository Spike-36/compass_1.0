import Foundation

public enum BlockElement {
    case header(type: String, number: String?, raw: String)
    case body(text: String)
}

public enum BlockHeaderDetector {

    // Strip sneaky bidi/control chars that break ^ anchors and word matches
    // U+200E/U+200F (LRM/RLM), U+202A–U+202E (embedding/override)
    private static let hiddenChars = CharacterSet(charactersIn: "\u{200E}\u{200F}\u{202A}\u{202B}\u{202C}\u{202D}\u{202E}")

    private static func normalize(_ s: String) -> String {
        let noHidden = s.unicodeScalars.filter { !hiddenChars.contains($0) }
        return String(String.UnicodeScalarView(noHidden))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Forgiving, case-insensitive patterns:
    //  - optional leading spaces
    //  - "Ans" or "Answer", "Stat" or "Statement"
    //  - optional dot before number
    //  - optional spaces around everything
    //  - optional trailing '.' or ':' after number
    private static let patterns: [(type: String, regex: NSRegularExpression)] = {
        let raw: [(String, String)] = [
            // Answer headers: "Ans.3.", "Ans 3:", "Answer 3", "answer.  12:"
            ("answer", #"^\s*(?:ans(?:wer)?)\s*\.?\s*(\d+)\s*[\.:]?\b"#),

            // Statement headers: "Stat 1.", "Stat.1", "Statement 2:"
            ("stat",   #"^\s*(?:stat(?:ement)?)\s*\.?\s*(\d+)\s*[\.:]?\b"#),

            // Condescendence styles (number captured if present)
            ("condescendence",        #"^\s*condescendence\s*\.?\s*(\d+)?\s*[\.:]?\b"#),
            ("articleCondescendence", #"^\s*article\s+of\s+condescendence\s*\.?\s*(\d+)?\s*[\.:]?\b"#)
        ]

        return raw.compactMap { (type, pat) in
            guard let re = try? NSRegularExpression(pattern: pat, options: [.caseInsensitive]) else { return nil }
            return (type, re)
        }
    }()

    /// Classify a single line of text as either a block header or body.
    public static func classify(_ line: String) -> BlockElement {
        let trimmed = normalize(line)
        guard !trimmed.isEmpty else { return .body(text: line) }

        let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
        for (type, regex) in patterns {
            if let m = regex.firstMatch(in: trimmed, options: [], range: range) {
                var number: String? = nil
                if m.numberOfRanges > 1, let r = Range(m.range(at: 1), in: trimmed) {
                    let n = String(trimmed[r]).trimmingCharacters(in: .whitespacesAndNewlines)
                    number = n.isEmpty ? nil : n
                }
                return .header(type: type, number: number, raw: trimmed)
            }
        }
        return .body(text: trimmed)
    }
}
//
//  BlockHeaderDetector.swift
//  Compass
//
//  Updated to handle "Ans.3.", "Answer 3:", "Stat.1", hidden bidi chars, etc.
//

