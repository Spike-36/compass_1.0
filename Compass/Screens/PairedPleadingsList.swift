//
//  PairedPleadingsList.swift
//  Compass
//

import SwiftUI
import SQLite3

// 🔗 Make sure FuzzyMatcher.swift is in the same target
// (no import needed if it's in the same module)
 
private struct SentencePair: Identifiable {
    let id: UUID = UUID()
    let statement: String?
    let answer: String?
}

private struct BlockResult {
    var blockNumber: Int
    var pairs: [SentencePair] = []
    var unmatchedStatements: [String] = []
    var unmatchedAnswers: [String] = []
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

private func defaultDBPath() -> String {
    let home = FileManager.default.homeDirectoryForCurrentUser
    return home.appendingPathComponent("Dev/Compass/compass.db").path
}

struct PairedPleadingsList: View {
    let docID: String
    @State private var blocks: [BlockResult] = []
    @State private var error: String?

    var body: some View {
        List {
            if let error = error {
                Text("⚠️ Error: \(error)").foregroundColor(.red)
            } else {
                ForEach(blocks, id: \.blockNumber) { block in
                    Section(header: Text("Block \(block.blockNumber)")) {
                        // Matched pairs
                        ForEach(block.pairs) { pair in
                            VStack(alignment: .leading, spacing: 4) {
                                if let s = pair.statement {
                                    Text("S: \(s)")
                                }
                                if let a = pair.answer {
                                    Text("A: \(a)")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }

                        // Unmatched statements
                        if !block.unmatchedStatements.isEmpty {
                            Text("Unmatched Statements:")
                                .font(.headline)
                            ForEach(block.unmatchedStatements, id: \.self) { s in
                                Text("S: \(s)")
                            }
                        }

                        // Unmatched answers
                        if !block.unmatchedAnswers.isEmpty {
                            Text("Unmatched Answers:")
                                .font(.headline)
                            ForEach(block.unmatchedAnswers, id: \.self) { a in
                                Text("A: \(a)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .onAppear(perform: load)
    }

    // MARK: - Data

    private func load() {
        print("🚀 load() triggered for docID=\(docID)")

        error = nil
        blocks.removeAll()

        var db: OpaquePointer?
        guard sqlite3_open(defaultDBPath(), &db) == SQLITE_OK, let db else {
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

        var map: [Int: ([String], [String])] = [:]

        while sqlite3_step(stmt) == SQLITE_ROW {
            let bt = String(cString: sqlite3_column_text(stmt, 0))
            let bn = Int(sqlite3_column_int(stmt, 1))
            let tx = clean(String(cString: sqlite3_column_text(stmt, 3)))

            var (statements, answers) = map[bn] ?? ([], [])
            if bt == "statement" {
                statements.append(tx)
            } else {
                answers.append(tx)
            }
            map[bn] = (statements, answers)
        }

        var results: [BlockResult] = []
        for (bn, (statements, answers)) in map.sorted(by: { $0.key < $1.key }) {
            var block = BlockResult(blockNumber: bn)

            var unmatchedStatements = statements
            var unmatchedAnswers = answers

            // 🔎 Try fuzzy matching
            for s in statements {
                print("🔎 [Block \(bn)] Checking statement: \(s.prefix(50))... against \(unmatchedAnswers.count) answers")
                var matched = false
                for (i, a) in unmatchedAnswers.enumerated() {
                    print("   ↔️ Compare with answer: \(a.prefix(50))...")
                    if FuzzyMatcher.isMatch(statement: s, answer: a, context: "Block \(bn)") {
                        print("✅ [Block \(bn)] MATCHED → \(s.prefix(30)) | \(a.prefix(30))")
                        block.pairs.append(SentencePair(statement: s, answer: a))
                        unmatchedAnswers.remove(at: i)
                        matched = true
                        break
                    }
                }
                if !matched {
                    block.unmatchedStatements.append(s)
                    print("❌ [Block \(bn)] No match for statement: \(s.prefix(50))...")
                }
            }

            // Leftover answers
            block.unmatchedAnswers.append(contentsOf: unmatchedAnswers)

            results.append(block)
        }

        self.blocks = results
        print("✅ Finished load(), found \(blocks.count) blocks")
    }

    // MARK: - Helpers

    private func clean(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\u{00A0}", with: " ") // NBSP → space
            .replacingOccurrences(of: "\u{00AD}", with: "")  // soft hyphen → remove
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        PairedPleadingsList(docID: "Roos.record.2007")
    }
}


