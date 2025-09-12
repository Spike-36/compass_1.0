import Foundation

/// Very basic exporter that turns paragraphs into <p> tags.
/// Produces visible HTML for debugging the render path.
enum HTMLExporter {

    /// Build a simple <article> with one <p> per paragraph.
    static func export(docID: String, version: Int, paragraphs: [String]) -> HTMLExportResult {
        var body = "<article>\n"
        var anchors: [String] = []

        if paragraphs.isEmpty {
            body += "<p><em>No paragraphs found (test filler).</em></p>\n"
        } else {
            for (i, p) in paragraphs.enumerated() {
                let anchor = "p\(i)"
                anchors.append(anchor)
                body += "<p id=\"\(anchor)\">\(escapeHTML(p))</p>\n"
            }
        }

        body += "</article>\n"

        // Counts
        let paraCount = paragraphs.count
        let sentCount = paragraphs.reduce(0) { count, p in
            count + p.split(separator: ".").count
        }

        // Write to temp file so WebView can load it
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("demo.html")
        try? body.write(to: tmpURL, atomically: true, encoding: .utf8)

        return HTMLExportResult(
            html: body,
            anchors: anchors,
            paraCount: paraCount,
            sentCount: sentCount,
            htmlURL: tmpURL
        )
    }

    // MARK: - Helpers

    private static func escapeHTML(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
    }
}

