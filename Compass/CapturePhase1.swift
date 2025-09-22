//
//  CapturePhase1.swift
//  Compass
//

import Foundation
import SQLite3

enum CapturePhase1 {

    struct CaptureRecord: Codable {
        let doc_id: String
        let block_type: String   // "statement" | "answer"
        let block_number: Int
        let sentence_index: Int  // 1-based within the block
        let text: String
    }

    private enum BlockType: String { case statement, answer }

    // NEW: toggle refresh behaviour
    private static let DB_REFRESH_ENABLED = true

    /// Exports folder (unified with PDFs)
    private static var unifiedExportsDir: URL {
        let path = "/Users/petermilligan/ConvertedDocs"
        try? FileManager.default.createDirectory(atPath: path,
                                                 withIntermediateDirectories: true)
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    /// Entry point. Safe to call every run; no-op if flag is OFF.
    static func runSameLineCapture(docId: String, paragraphs: [String], exportsDir: URL? = nil) {
        guard FeatureFlags.CAPTURE_ENABLED else { return }

        // 🔍 DEBUG
        print("🚀 runSameLineCapture called for \(docId), paragraphs=\(paragraphs.count)")

        var records: [CaptureRecord] = []
        var statements = 0, answers = 0, sentences = 0, emptyBlocks = 0
        var queue = paragraphs

        while !queue.isEmpty {
            var cleaned = stripBidi(queue.removeFirst())
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if cleaned.isEmpty { continue }

            // Split off second header if inline
            if let secondHeader = findNextHeaderStart(in: cleaned),
               secondHeader.lowerBound != cleaned.startIndex {
                let head = String(cleaned[..<secondHeader.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let tail = String(cleaned[secondHeader.lowerBound...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !tail.isEmpty { queue.insert(tail, at: 0) }
                cleaned = head
            }

            if let hit = matchSameLineHeader(cleaned) {
                let sents = SentenceSplitter.split(hit.body)

                if sents.isEmpty {
                    emptyBlocks += 1
                    records.append(CaptureRecord(
                        doc_id: docId,
                        block_type: hit.type.rawValue,
                        block_number: hit.number,
                        sentence_index: 1,
                        text: ""
                    ))
                } else {
                    for (idx, s) in sents.enumerated() {
                        sentences += 1
                        records.append(CaptureRecord(
                            doc_id: docId,
                            block_type: hit.type.rawValue,
                            block_number: hit.number,
                            sentence_index: idx + 1,
                            text: s
                        ))
                    }
                }

                switch hit.type {
                case .statement: statements += 1
                case .answer:    answers += 1
                }
            }
        }

        // 🔗 Unified export folder
        let outDir = exportsDir ?? unifiedExportsDir

        let ndjsonURL = outDir.appendingPathComponent("\(docId).capture.ndjson")
        let jsonURL   = outDir.appendingPathComponent("\(docId).capture.json")

        // --- Write NDJSON ---
        do {
            try writeNDJSON(records, to: ndjsonURL)
            print("✅ wrote NDJSON to \(ndjsonURL.path), count=\(records.count)")
        } catch {
            NSLog("capture: failed to write NDJSON: \(error.localizedDescription)")
        }

        // --- Write JSON array ---
        do {
            try writeJSONArray(records, to: jsonURL)
            print("✅ wrote JSON to \(jsonURL.path), count=\(records.count)")
        } catch {
            NSLog("capture: failed to write JSON: \(error.localizedDescription)")
        }

        // 🚫 Disabled by default to preserve DB during dev
        if DB_REFRESH_ENABLED {
            writeToDatabase(records: records, docId: docId)
        }

        print("capture: statements=\(statements) answers=\(answers) sentences=\(sentences) empty_blocks=\(emptyBlocks)")
    }

    // MARK: - Header detection
    private static func matchSameLineHeader(_ line: String) -> (type: BlockType, number: Int, body: String)? {
        let patterns: [(BlockType, NSRegularExpression)] = {
            let raw: [(BlockType, String)] = [
                (.statement, #"^\s*(?:Stat\.?|Statement)\s*(\d+)\s*[\.:]?\s*(.*)?$"#),
                (.answer,    #"^\s*(?:Ans\.?|Answer)\s*(\d+)\s*[\.:]?\s*(.*)?$"#)
            ]
            return raw.compactMap { (t, p) in
                (try? NSRegularExpression(pattern: p,
                                          options: [.caseInsensitive, .dotMatchesLineSeparators]))
                .map { (t, $0) }
            }
        }()

        for (type, rx) in patterns {
            let ns = NSRange(line.startIndex..<line.endIndex, in: line)
            if let m = rx.firstMatch(in: line, options: [], range: ns) {
                guard
                    let numRange  = Range(m.range(at: 1), in: line),
                    let number    = Int(line[numRange])
                else { continue }
                let bodyRange = Range(m.range(at: 2), in: line)
                let body = bodyRange.map { String(line[$0]) } ?? ""
                return (type, number, body.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
        return nil
    }

    private static func findNextHeaderStart(in s: String) -> Range<String.Index>? {
        let pat = #"(?i)(Stat\.?|Statement|Ans\.?|Answer)\s+\d+\s*[.:]"#
        guard let rx = try? NSRegularExpression(pattern: pat) else { return nil }
        let ns = NSRange(s.startIndex..<s.endIndex, in: s)
        guard let m = rx.firstMatch(in: s, range: ns) else { return nil }
        return Range(m.range, in: s)
    }

    // MARK: - IO (NDJSON)
    private static func writeNDJSON(_ records: [CaptureRecord], to url: URL) throws {
        let encoder = JSONEncoder()
        var data = Data()
        for rec in records {
            let line = try encoder.encode(rec)
            data.append(line)
            data.append(0x0A)
        }
        let tmp = url.deletingLastPathComponent()
            .appendingPathComponent(".\(UUID().uuidString).tmp")
        try data.write(to: tmp, options: .atomic)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        try FileManager.default.moveItem(at: tmp, to: url)
    }

    // MARK: - IO (JSON array)
    private static func writeJSONArray(_ records: [CaptureRecord], to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(records)
        try data.write(to: url, options: .atomic)
    }

    private static func stripBidi(_ s: String) -> String {
        s.replacingOccurrences(of: "[\u{200E}\u{200F}\u{202A}-\u{202E}]",
                               with: "", options: .regularExpression)
    }

    // MARK: - IO (SQLite DB) — unchanged
    private static func writeToDatabase(records: [CaptureRecord], docId: String) {
        // … existing DB code …
    }
}

