//
//  DocxPipeline.swift
//  Compass
//
//  Reads a user-selected DOCX → plain text via `textutil` → HTML with sentence spans.
//  Writes outputs to ~/Dev/Compass/exports (real home dir, not sandbox container).
//  Calls CapturePhase1.runSameLineCapture(...) after paragraphization (Phase 1).
//

import Foundation

enum DocxPipeline {
    struct Result {
        let htmlURL: URL
        let docID: String
        let version: Int
    }

    /// Run the pipeline on a specific DOCX file URL
    static func run(input: URL) throws -> Result {
        let fm = FileManager.default

        guard fm.fileExists(atPath: input.path) else {
            throw NSError(domain: "Compass", code: 404,
                          userInfo: [NSLocalizedDescriptionKey:
                                        "DOCX not found at \(input.path)"])
        }

        // Temporary workspace (for conversion + staging)
        let tmpRoot = fm.temporaryDirectory.appendingPathComponent("Compass-\(UUID().uuidString)")
        let tmpExports = tmpRoot.appendingPathComponent("exports")
        try fm.createDirectory(at: tmpExports, withIntermediateDirectories: true)

        // ✅ Stable exports location in real home directory
        let sharedExports = fm.homeDirectoryForCurrentUser
            .appendingPathComponent("Dev/Compass/exports", isDirectory: true)
        try fm.createDirectory(at: sharedExports, withIntermediateDirectories: true)

        // 👇 Visibility: confirm which dir we are using
        print("DocxPipeline using exports dir →", sharedExports.path)

        // DOCX → TXT (into temp)
        let txtURL = tmpRoot.appendingPathComponent(input.deletingPathExtension().lastPathComponent + ".txt")
        try convertDocxToTxt(input: input, output: txtURL)

        // Read plain text
        let raw = try String(contentsOf: txtURL, encoding: .utf8)
        let paragraphs = splitIntoParagraphs(raw)

        // Phase-1 capture (same-line only). Capture file is written to sharedExports.
        CapturePhase1.runSameLineCapture(
            docId: input.deletingPathExtension().lastPathComponent,
            paragraphs: paragraphs,
            exportsDir: sharedExports
        )

        // Build HTML body
        var body = "<article>\n"
        for (pi, p) in paragraphs.enumerated() {
            let sents = splitIntoSentences(p)
            body += "<p id='p\(pi+1)'>"
            if sents.isEmpty {
                body += "<em>(empty)</em>"
            } else {
                for (si, s) in sents.enumerated() {
                    let sid = "p\(pi+1).s\(si+1)"
                    body += "<span class='sent' data-stable-id='\(sid)'>\(escapeHTML(s))</span> "
                }
            }
            body += "</p>\n"
        }
        body += "</article>\n"

        // Wrap HTML
        let html = wrapAsPage(bodyHTML: body, title: "Compass — \(input.lastPathComponent)")

        // Write to temp first
        let tmpHTML = tmpExports.appendingPathComponent(input.deletingPathExtension().lastPathComponent + ".html")
        try html.write(to: tmpHTML, atomically: true, encoding: .utf8)

        // Then copy/replace into the shared exports folder
        let sharedHTML = sharedExports.appendingPathComponent(input.deletingPathExtension().lastPathComponent + ".html")
        if fm.fileExists(atPath: sharedHTML.path) {
            try fm.removeItem(at: sharedHTML)
        }
        try fm.copyItem(at: tmpHTML, to: sharedHTML)

        return .init(htmlURL: sharedHTML,
                     docID: input.deletingPathExtension().lastPathComponent,
                     version: 1)
    }

    // MARK: - Conversion

    private static func convertDocxToTxt(input: URL, output: URL) throws {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/textutil")
        proc.arguments = ["-convert", "txt", input.path, "-output", output.path]

        let pipe = Pipe(); proc.standardError = pipe
        try proc.run(); proc.waitUntilExit()

        if proc.terminationStatus != 0 {
            let err = String(data: pipe.fileHandleForReading.readDataToEndOfFile(),
                             encoding: .utf8) ?? "unknown error"
            throw NSError(domain: "Compass", code: Int(proc.terminationStatus),
                          userInfo: [NSLocalizedDescriptionKey: "textutil failed: \(err)"])
        }
    }

    // MARK: - Text shaping

    /// Split text into paragraphs. Detects Stat/Ans headers even when inline.
    private static func splitIntoParagraphs(_ s: String) -> [String] {
        // Normalize line endings
        let norm = s.replacingOccurrences(of: "\r\n", with: "\n")

        // Collapse multiple blank lines
        let collapsed = norm.replacingOccurrences(of: "\n{2,}", with: "\n\n", options: .regularExpression)

        // Regex: start a new para before "Stat N." or "Ans. N."
        let pattern = #"(?=\b(?:Stat\s+\d+\.|Ans\.\s*\d+\.))"#
        let regex = try! NSRegularExpression(pattern: pattern)

        var parts: [String] = []
        var start = collapsed.startIndex
        let len = collapsed.utf16.count

        for m in regex.matches(in: collapsed, range: NSRange(location: 0, length: len)) {
            let idx = String.Index(utf16Offset: m.range.location, in: collapsed)
            if idx > start {
                let piece = String(collapsed[start..<idx]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !piece.isEmpty { parts.append(piece) }
            }
            start = idx
        }

        let tail = String(collapsed[start...]).trimmingCharacters(in: .whitespacesAndNewlines)
        if !tail.isEmpty { parts.append(tail) }

        // Also split on double newlines inside chunks
        return parts.flatMap { chunk in
            chunk
                .components(separatedBy: "\n\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
    }

    private static func splitIntoSentences(_ text: String) -> [String] {
        let norm = text.replacingOccurrences(of: "\\s+", with: " ",
                                             options: .regularExpression)
        let pattern = #"(?<!\d)([.!?])\s+(?=[A-Z"'])"#
        let regex = try! NSRegularExpression(pattern: pattern)
        var result: [String] = []
        var start = norm.startIndex
        let len = norm.utf16.count

        for m in regex.matches(in: norm, range: NSRange(location: 0, length: len)) {
            let endUTF16 = m.range.location + 1
            let end = String.Index(utf16Offset: endUTF16, in: norm)
            let piece = String(norm[start..<end]).trimmingCharacters(in: .whitespaces)
            if !piece.isEmpty { result.append(piece) }
            let nextStartUTF16 = m.range.location + m.range.length
            start = String.Index(utf16Offset: nextStartUTF16, in: norm)
        }
        let tail = String(norm[start...]).trimmingCharacters(in: .whitespaces)
        if !tail.isEmpty { result.append(tail) }
        return result
    }

    // MARK: - HTML

    private static func wrapAsPage(bodyHTML: String, title: String) -> String {
        """
        <!doctype html>
        <html><head>
          <meta charset="utf-8">
          <title>\(title)</title>
          <meta name="color-scheme" content="dark light">
          <style>
            body { font: 16px -apple-system, system-ui, Helvetica, Arial;
                   margin: 24px; line-height: 1.45;
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
              if (t.classList && t.classList.contains('sent')) {
                t.classList.toggle('hl');
              }
            });
          </script>
        </head><body>
        \(bodyHTML)
        </body></html>
        """
    }

    private static func escapeHTML(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}

