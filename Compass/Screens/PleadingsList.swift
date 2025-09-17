//
//  PleadingsList.swift
//  Compass
//

import SwiftUI
import SQLite3

private struct PleadingSentenceRow: Identifiable {
    let id: String
    let blockType: String     // "statement" | "answer"
    let blockNumber: Int
    let sentenceIndex: Int
    let text: String
}

private struct BlockPair {
    var statement: [PleadingSentenceRow] = []
    var answer: [PleadingSentenceRow] = []
}

/// Where your live DB is (same as DatabaseViewer)
private func defaultDBPath() -> String {
    let home = FileManager.default.homeDirectoryForCurrentUser
    return home.appendingPathComponent("Dev/Compass/compass.db").path
}

struct PleadingsList: View {
    // Pass whichever doc you want to inspect
    var docID: String

    @State private var sections: [(block: Int, pair: BlockPair)] = []
    @State private var rowCount: Int = 0
    @State private var error: String?
    @State private var dbPath: String = defaultDBPath()

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
            .navigationTitle("Sentence View")
            .onAppear(perform: load)
        }
    }

    // MARK: - Data

    private func load() {
        error = nil
        sections.removeAll()
        rowCount = 0

        guard FileManager.default.fileExists(atPath: dbPath) else {
            error = "DB not found at \(dbPath)"
            return
        }

        var db: OpaquePointer?
        guard sqlite3_open(dbPath, &db) == SQLITE_OK, let db else {
            error = "Failed to open DB"
            return
        }
        defer { sqlite3_close(db) }

        // DISTINCT removes duplicate sentences
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

        var map: [Int: BlockPair] = [:]
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

            let row = PleadingSentenceRow(
                id: "\(bt)-\(bn)-\(si)-\(idx)",
                blockType: bt,
                blockNumber: bn,
                sentenceIndex: si,
                text: tx
            )

            var pair = map[bn] ?? BlockPair()
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
        PleadingsList(docID: "Roos.record.2007")
    }
}

