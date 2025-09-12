import Foundation

public enum SentenceSplitter {
    // Minimal splitter to get you compiling.
    // Splits on ., !, ? and trims spaces. We’ll improve later.
    public static func split(_ paragraph: String) -> [String] {
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

        // trailing fragment (no terminal punctuation)
        let tail = cur.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tail.isEmpty { parts.append(tail) }

        return parts
    }
}

