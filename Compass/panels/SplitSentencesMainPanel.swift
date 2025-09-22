//
//  SplitSentencesMainPanel.swift
//  Compass
//
//  Created by Pete on 20/09/2025.
//

import SwiftUI
import SQLite3

/// A single sentence row in split-sentences mode
private struct SplitSentenceRow: Identifiable {
    let id: String
    let blockType: String     // "statement" | "answer"
    let blockNumber: Int
    let sentenceIndex: Int
    let text: String
}

/// A statement/answer block pair in split-sentences mode
private struct SplitBlockPair {
    var statement: [SplitSentenceRow] = []
    var answer: [SplitSentenceRow] = []
}

struct SplitSentencesMainPanel: View {
    // Default doc so previews and navigation calls don’t break
    var docID: String = "Roos.record.2007"

    @State private var sections: [(block: Int, pair: SplitBlockPair)] = []
    @State private var rowCount: Int = 0
    @State private var error: String?
    @State private var dbPath: String = "(bundle)"

    var body: some View {
        VStack(spacing: 0) {
            // Small header with current DB path (helps debugging)
            HStack(spacing: 8) {
                Text("DB:").font(.caption).foregroundColor(.secondary)
                Text(dbPath).font(.caption.monospaced())
                    .lineLimit(1).truncationMode(.middle)
                Spacer()
                Text("Rows: \(rowCount)").font(.caption.monospaced())
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(nsColor: .windowBackgroundColor))

            if let error {
                Text(error).foregroundColor(.red).font(.caption).padding(.horizontal)
            }

            List {
                ForEach(sections, id: \.block) { (block, pair) in
                    // Statement N
                    Section {
                        ForEach(pair.statement) { r in
                            Text(r.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.vertical, 6)
                        }
                    } header: {
                        Text("Statement \(block)")
                            .font(.headline)
                    }

                    // Answer N
                    Section {
                        ForEach(pair.answer) { r in
                            Text(r.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.vertical, 6)
                        }
                    } header: {
                        Text("Answer \(block)")
                            .font(.headline)
                    }
                }
            }
            .listStyle(.inset)
            .navigationTitle("Split Sentences")
            .onAppear(perform: load)
        }
    }

    // MARK: - Data

    private func load() {
        error = nil
        sections.removeAll()
        rowCount = 0

        // Resolve bundled DB
        guard let dbURL = Bundle.main.url(forResource: "compass", withExtension: "db") else {
            error = "Database not found in bundle"
            return
        }
        dbPath = dbURL.lastPathComponent

        var db: OpaquePointer?
        guard sqlite3_open(dbURL.path, &db) == SQLITE_OK, let db else {
            error = "Failed to open DB"
            return
        }
        defer { sqlite3_close(db) }

        let sql = """
        SELECT DISTINCT block_type, block_number, sentence_index, text
        FROM sentences
        WHERE doc_id = ?
        ORDER BY block_number ASC,
                 CASE block_type WHEN 'statement' THEN 0 ELSE 1 END,
                 sentence_index ASC
        """

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else {
            error = "Prepare failed."
            return
        }
        defer { sqlite3_finalize(stmt) }

        // bind doc_id
        sqlite3_bind_text(stmt, 1, (docID as NSString).utf8String, -1, SQLITE_TRANSIENT)

        var map: [Int: SplitBlockPair] = [:]
        var count = 0
        var idx = 0

        while sqlite3_step(stmt) == SQLITE_ROW {
            let bt = String(cString: sqlite3_column_text(stmt, 0))
            let bn = Int(sqlite3_column_int(stmt, 1))
            let si = Int(sqlite3_column_int(stmt, 2))

            // Normalize the text so wrapping works properly
            var tx = String(cString: sqlite3_column_text(stmt, 3))
            tx = tx
                .replacingOccurrences(of: "\r\n", with: " ")
                .replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: "\r", with: " ")
                .replacingOccurrences(of: "\u{00A0}", with: " ") // NBSP → space
                .replacingOccurrences(of: "\u{00AD}", with: "")  // soft hyphen → remove

            let row = SplitSentenceRow(
                id: "\(bt)-\(bn)-\(si)-\(idx)",
                blockType: bt,
                blockNumber: bn,
                sentenceIndex: si,
                text: tx
            )

            var pair = map[bn] ?? SplitBlockPair()
            if bt == "statement" {
                pair.statement.append(row)
            } else {
                pair.answer.append(row)
            }
            map[bn] = pair
            count += 1
            idx += 1

            if count >= 1000 { break } // v1 guardrail
        }

        let ordered = map.keys.sorted().compactMap { key in
            map[key].map { (key, $0) }
        }
        sections = ordered
        rowCount = count
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        SplitSentencesMainPanel(docID: "Roos.record.2007")
    }
}

