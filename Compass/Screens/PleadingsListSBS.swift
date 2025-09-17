
//
//  PleadingsListSBS.swift
//  Compass
//

import SwiftUI
import SQLite3

private struct PleadingSentenceRow: Identifiable {
    let id: String
    let blockType: String
    let blockNumber: Int
    let sentenceIndex: Int
    let text: String
}

private struct BlockPair: Identifiable {
    let id: Int
    var statement: [PleadingSentenceRow] = []
    var answer: [PleadingSentenceRow] = []
}

private func defaultDBPath() -> String {
    let home = FileManager.default.homeDirectoryForCurrentUser
    return home.appendingPathComponent("Dev/Compass/compass.db").path
}

struct PleadingsListSBS: View {
    var docID: String

    @State private var sections: [BlockPair] = []
    @State private var rowCount: Int = 0
    @State private var error: String?
    @State private var dbPath: String = defaultDBPath()

    var body: some View {
        VStack(spacing: 0) {
            // Header bar
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
                ForEach(sections) { pair in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Block \(pair.id)")
                            .font(.headline)
                            .padding(.bottom, 4)

                        HStack(alignment: .top, spacing: 24) {
                            // Statement column
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(pair.statement) { r in
                                    Text(r.text)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            // Answer column
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(pair.answer) { r in
                                    Text(r.text)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .listStyle(.inset)
            .navigationTitle("Side by Side")
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

        sqlite3_bind_text(stmt, 1, (docID as NSString).utf8String, -1, SQLITE_TRANSIENT)

        var map: [Int: BlockPair] = [:]
        var count = 0
        var idx = 0

        while sqlite3_step(stmt) == SQLITE_ROW {
            let bt = String(cString: sqlite3_column_text(stmt, 0))
            let bn = Int(sqlite3_column_int(stmt, 1))
            let si = Int(sqlite3_column_int(stmt, 2))
            var tx = String(cString: sqlite3_column_text(stmt, 3))

            // normalize for wrapping
            tx = tx
                .replacingOccurrences(of: "\r\n", with: " ")
                .replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: "\r", with: " ")
                .replacingOccurrences(of: "\u{00A0}", with: " ")
                .replacingOccurrences(of: "\u{00AD}", with: "")

            let row = PleadingSentenceRow(
                id: "\(bt)-\(bn)-\(si)-\(idx)",
                blockType: bt,
                blockNumber: bn,
                sentenceIndex: si,
                text: tx
            )
            idx += 1

            var pair = map[bn] ?? BlockPair(id: bn)
            if bt == "statement" {
                pair.statement.append(row)
            } else {
                pair.answer.append(row)
            }
            map[bn] = pair
            count += 1
            if count >= 1000 { break }
        }

        sections = map.keys.sorted().compactMap { map[$0] }
        rowCount = count
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        PleadingsListSBS(docID: "Roos.record.2007")
    }
}
