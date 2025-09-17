//
//  PairedPleadingsList.swift
//  Compass
//

import SwiftUI
import SQLite3
import UniformTypeIdentifiers

// ── Model ────────────────────────────────────────────────────────────────────

private struct SentenceItem: Identifiable, Hashable {
    let id: Int
    let text: String
    var linkedResponseIds: [Int] = []
}

private struct BlockColumn: Identifiable {
    let id: Int          // blockNumber
    let statements: [SentenceItem]
    let answers: [SentenceItem]
}

// ── DB helpers ───────────────────────────────────────────────────────────────

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

private func defaultDBPath() -> String {
    FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent("Dev/Compass/compass.db").path
}

// ── View ─────────────────────────────────────────────────────────────────────

struct PairedPleadingsList: View {
    let docID: String

    @State private var blocks: [BlockColumn] = []
    @State private var error: String?

    var body: some View {
        List {
            if let error {
                Text("⚠️ \(error)").foregroundColor(.red)
            } else if blocks.isEmpty {
                Text("No rows found for \(docID)").foregroundColor(.secondary)
            } else {
                ForEach(blocks) { block in
                    Section(header: Text("Block \(block.id)")) {
                        HStack(alignment: .top, spacing: 16) {

                            // Left: Statements (drop target)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Statements (\(block.statements.count))")
                                    .font(.headline)
                                ForEach(block.statements) { s in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(s.text)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .onDrop(of: [UTType.plainText.identifier],
                                                    isTargeted: nil) { providers in
                                                if let provider = providers.first {
                                                    _ = provider.loadObject(ofClass: String.self) { (str, _) in
                                                        if let str, let droppedId = Int(str) {
                                                            print("🟢 Dropped answer=\(droppedId) onto statement=\(s.id)")
                                                        }
                                                    }
                                                    return true
                                                }
                                                return false
                                            }

                                        if !s.linkedResponseIds.isEmpty {
                                            let idsString = s.linkedResponseIds
                                                .map { String($0) }
                                                .joined(separator: ", ")
                                            Text("↳ linked ids: \(idsString)")
                                                .font(.caption)
                                                .foregroundColor(.red)

                                            ForEach(s.linkedResponseIds, id: \.self) { rid in
                                                if let ans = block.answers.first(where: { $0.id == rid }) {
                                                    Text("↳ \(ans.text)")
                                                        .font(.caption)
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            // Right: Answers (drag source)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Answers (\(block.answers.count))")
                                    .font(.headline)
                                ForEach(block.answers) { a in
                                    Text(a.text)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .onDrag {
                                            print("🟢 Dragging answer id=\(a.id)")
                                            return NSItemProvider(object: String(a.id) as NSString)
                                        }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .onAppear(perform: load)
        .navigationTitle("Paired Pleadings")
    }

    // ── Data Load ────────────────────────────────────────────────────────────

    private func load() {
        error = nil
        blocks.removeAll()

        DispatchQueue.global(qos: .userInitiated).async {
            var db: OpaquePointer?
            let path = defaultDBPath()
            guard sqlite3_open(path, &db) == SQLITE_OK, let db else {
                DispatchQueue.main.async {
                    self.error = "Failed to open DB at \(path)"
                }
                return
            }
            defer { sqlite3_close(db) }

            var map: [Int: (statements: [SentenceItem], answers: [SentenceItem])] = [:]

            // 1. Sentences
            let sql = """
            SELECT id, block_type, block_number, sentence_index, text
            FROM sentences
            WHERE doc_id = ?
            ORDER BY block_number ASC,
                     CASE block_type WHEN 'statement' THEN 0 ELSE 1 END,
                     sentence_index ASC;
            """

            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else {
                DispatchQueue.main.async {
                    self.error = "Prepare failed."
                }
                return
            }
            defer { sqlite3_finalize(stmt) }

            sqlite3_bind_text(stmt, 1, (docID as NSString).utf8String, -1, SQLITE_TRANSIENT)

            while sqlite3_step(stmt) == SQLITE_ROW {
                let sid = Int(sqlite3_column_int(stmt, 0))
                let blockType = String(cString: sqlite3_column_text(stmt, 1))
                let blockNum = Int(sqlite3_column_int(stmt, 2))
                let text = clean(String(cString: sqlite3_column_text(stmt, 4)))

                var bucket = map[blockNum] ?? ([], [])
                let item = SentenceItem(id: sid, text: text)
                if blockType == "statement" {
                    bucket.statements.append(item)
                } else {
                    bucket.answers.append(item)
                }
                map[blockNum] = bucket
            }

            // 2. Links
            let linkSQL = "SELECT statement_id, response_id FROM links;"
            var linkStmt: OpaquePointer?
            if sqlite3_prepare_v2(db, linkSQL, -1, &linkStmt, nil) == SQLITE_OK, let linkStmt {
                while sqlite3_step(linkStmt) == SQLITE_ROW {
                    let statementId = Int(sqlite3_column_int(linkStmt, 0))
                    let responseId  = Int(sqlite3_column_int(linkStmt, 1))
                    print("🔗 Link found: \(statementId) → \(responseId)")

                    for (blockNum, bucket) in map {
                        if let idx = bucket.statements.firstIndex(where: { $0.id == statementId }) {
                            var updatedStatements = bucket.statements
                            updatedStatements[idx].linkedResponseIds.append(responseId)
                            map[blockNum] = (updatedStatements, bucket.answers)
                        }
                    }
                }
                sqlite3_finalize(linkStmt)
            }

            // 3. Build result
            let results = map.keys.sorted().map { bn in
                let b = map[bn]!
                return BlockColumn(id: bn, statements: b.statements, answers: b.answers)
            }

            DispatchQueue.main.async {
                self.blocks = results
                print("DEBUG: Loaded \(results.count) block(s)")
            }
        }
    }

    // ── Utilities ───────────────────────────────────────────────────────────

    private func clean(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{00AD}", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        PairedPleadingsList(docID: "Roos.record.2007")
    }
}

