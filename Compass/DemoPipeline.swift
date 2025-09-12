//
//  DemoPipeline.swift
//  Compass
//

import Foundation

enum DemoPipeline {
    struct Result { let htmlURL: URL; let docID: String; let version: Int }

    static func run() throws -> Result {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("CompassDemo-\(UUID().uuidString)")
        let exports = root.appendingPathComponent("exports")
        try fm.createDirectory(at: exports, withIntermediateDirectories: true)

        // Known-good sample paragraphs (no DOCX, no parsing).
        let paragraphs: [String] = [
            "14. The defendant admits the signature. The notice is disputed.",
            "15. Mr. Smith says the value is £3.5m. It is contested."
        ]

        // Build body HTML with sentence spans (pN.sM stable IDs)
        var body = "<article>\n"
        for (pi, p) in paragraphs.enumerated() {
            let sents = splitIntoSentences(p)
            body += "<p id='p\(pi)'>"
            if sents.isEmpty {
                body += "<em>(empty)</em>"
            } else {
                for (si, s) in sents.enumerated() {
                    let sid = "p\(pi).s\(si+1)"
                    body += "<span class='sent' data-stable-id='\(sid)'>\(escapeHTML(s))</span> "
                }
            }
            body += "</p>\n"
        }
        body += "</article>\n"

        // Wrap into a complete page (dark-mode friendly).
        let html = wrapAsPage(bodyHTML: body, title: "Compass Demo — pleadingA@v1")
        let out = exports.appendingPathComponent("demo.html")
        try html.write(to: out, atomically: true, encoding: .utf8)

        return .init(htmlURL: out, docID: "pleadingA", version: 1)
    }

    // MARK: - Naive sentence splitter (demo-grade)
    // Splits on . ! ? followed by whitespace + an uppercase/quote.
    // Keeps punctuation with the sentence; avoids splitting decimals like 3.5.
    private static func splitIntoSentences(_ text: String) -> [String] {
        let norm = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        let pattern = #"([.!?])\s+(?=[A-Z"'])"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])

        var result: [String] = []
        var start = norm.startIndex

        let length = norm.utf16.count
        for m in regex.matches(in: norm, range: NSRange(location: 0, length: length)) {
            // include the punctuation (group 1) in the sentence
            let endUTF16 = m.range.location + 1
            let end = String.Index(utf16Offset: endUTF16, in: norm)
            let piece = String(norm[start..<end]).trimmingCharacters(in: .whitespaces)
            if !piece.isEmpty { result.append(piece) }

            // move start to after the whitespace matched by the regex
            let nextStartUTF16 = m.range.location + m.range.length
            start = String.Index(utf16Offset: nextStartUTF16, in: norm)
        }

        // Tail
        let tail = String(norm[start...]).trimmingCharacters(in: .whitespaces)
        if !tail.isEmpty { result.append(tail) }

        return result
    }

    // MARK: - Page wrapper

    private static func wrapAsPage(bodyHTML: String, title: String) -> String {
        """
        <!doctype html>
        <html><head>
          <meta charset="utf-8">
          <title>\(title)</title>
          <meta name="color-scheme" content="dark light">
          <style>
            body { font-family: -apple-system, system-ui, Helvetica, Arial; margin: 24px; line-height: 1.45;
                   color: #fff; background: #121212; }
            article { max-width: 900px; }
            p { margin: 0 0 12px 0; }
            .sent { padding: 1px 2px; border-radius: 3px; cursor: pointer; }
            .sent:hover { outline: 1px dashed #999; }
            .sent.hl { background: #fff59d; color: #000; }
          </style>
          <script>
            addEventListener('click', function(e){
              var t = e.target;
              if(t.classList && t.classList.contains('sent')){ t.classList.toggle('hl'); }
            });
          </script>
        </head><body>
        \(bodyHTML)
        </body></html>
        """
    }

    // MARK: - Helpers

    private static func escapeHTML(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
    }
}

