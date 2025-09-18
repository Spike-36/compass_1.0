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

// ── Main View ────────────────────────────────────────────────────────────────

struct PairedPleadingsList: View {
    let docID: String

    @State private var blocks: [BlockColumn] = []
    @State private var error: String?
    @State private var scrollTarget: Int?

    var body: some View {
        ScrollViewReader { proxy in
            List {
                if let error {
                    ErrorView(error: error)
                } else if blocks.isEmpty {
                    EmptyView(docID: docID)
                } else {
                    ForEach(blocks) { block in
                        BlockSection(
                            block: block,
                            scrollTarget: $scrollTarget,
                            reload: load
                        )
                    }
                }
            }
            // ✅ Fix: track only IDs so Equatable works
            .onChange(of: blocks.map(\.id)) { _ in
                if let target = scrollTarget {
                    print("🔄 onChange fired → attempting scrollTo(\(target))")
                    withAnimation {
                        proxy.scrollTo(target, anchor: .top)
                    }
                    print("✅ scrollTo complete, clearing target")
                    scrollTarget = nil
                } else {
                    print("ℹ️ onChange fired but no scrollTarget set")
                }
            }
        }
        .onAppear {
            print("📥 PairedPleadingsList appeared → calling load()")
            load()
        }
        .navigationTitle("Paired Pleadings")
    }

    // ── Data Load ────────────────────────────────────────────────────────────

    private func load() {
        error = nil
        blocks.removeAll()
        print("📡 Loading data for docID=\(docID)")

        DispatchQueue.global(qos: .userInitiated).async {
            var map: [Int: (statements: [SentenceItem], answers: [SentenceItem])] = [:]

            // 1. Sentences
            let sql = """
            SELECT id, block_type, block_number, text,
                   CASE block_type WHEN 'statement' THEN 0 ELSE 1 END AS sort_order
            FROM sentences
            WHERE doc_id = ?
            ORDER BY block_number ASC, sort_order ASC;
            """

            DatabaseManager.shared.query(
                sql: sql,
                bind: { stmt in
                    sqlite3_bind_text(stmt, 1, (docID as NSString).utf8String, -1, SQLITE_TRANSIENT)
                },
                row: { stmt in
                    let sid = Int(sqlite3_column_int(stmt, 0))
                    let blockType = String(cString: sqlite3_column_text(stmt, 1))
                    let blockNum = Int(sqlite3_column_int(stmt, 2))
                    let text = clean(String(cString: sqlite3_column_text(stmt, 3)))

                    var bucket = map[blockNum] ?? ([], [])
                    let item = SentenceItem(id: sid, text: text)
                    if blockType == "statement" {
                        bucket.statements.append(item)
                    } else {
                        bucket.answers.append(item)
                    }
                    map[blockNum] = bucket
                }
            )

            // 2. Links
            DatabaseManager.shared.query(
                sql: "SELECT statement_id, response_id FROM links;"
            ) { stmt in
                let statementId = Int(sqlite3_column_int(stmt, 0))
                let responseId  = Int(sqlite3_column_int(stmt, 1))

                for (blockNum, bucket) in map {
                    if let idx = bucket.statements.firstIndex(where: { $0.id == statementId }) {
                        var updatedStatements = bucket.statements
                        updatedStatements[idx].linkedResponseIds.append(responseId)
                        map[blockNum] = (updatedStatements, bucket.answers)
                    }
                }
            }

            // 3. Build result
            let results = map.keys.sorted().map { bn in
                let b = map[bn]!
                return BlockColumn(id: bn, statements: b.statements, answers: b.answers)
            }

            DispatchQueue.main.async {
                print("📦 Data load complete → \(results.count) blocks")
                self.blocks = results
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

// ── Subviews ────────────────────────────────────────────────────────────────

private struct ErrorView: View {
    let error: String
    var body: some View {
        Text("⚠️ \(error)").foregroundColor(.red)
    }
}

private struct EmptyView: View {
    let docID: String
    var body: some View {
        Text("No rows found for \(docID)").foregroundColor(.secondary)
    }
}

private struct BlockSection: View {
    let block: BlockColumn
    @Binding var scrollTarget: Int?
    let reload: () -> Void

    var body: some View {
        Section(header: Text("Block \(block.id)")) {
            HStack(alignment: .top, spacing: 16) {
                StatementColumn(block: block, scrollTarget: $scrollTarget, reload: reload)
                AnswerColumn(block: block, scrollTarget: $scrollTarget, reload: reload)
            }
            .padding(.vertical, 4)
        }
    }
}

private struct StatementColumn: View {
    let block: BlockColumn
    @Binding var scrollTarget: Int?
    let reload: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Statements (\(block.statements.count))")
                .font(.headline)
            ForEach(block.statements) { s in
                VStack(alignment: .leading, spacing: 4) {
                    Text(s.text)
                        .id(s.id)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        // Accept response → statement
                        .onDrop(of: [UTType.plainText.identifier], isTargeted: nil) { providers in
                            if let provider = providers.first {
                                _ = provider.loadObject(ofClass: String.self) { (str, _) in
                                    if let str, let droppedId = Int(str) {
                                        print("🟢 Drop Response→Statement: responseId=\(droppedId), statementId=\(s.id)")
                                        let ok = DB.shared.insertLink(statementId: s.id, responseId: droppedId)
                                        if ok {
                                            DispatchQueue.main.async {
                                                print("📌 Setting scrollTarget=\(s.id)")
                                                scrollTarget = s.id
                                                reload()
                                            }
                                        }
                                    }
                                }
                                return true
                            }
                            return false
                        }
                        // Enable statement → response
                        .onDrag {
                            NSItemProvider(object: String(s.id) as NSString)
                        }

                    if !s.linkedResponseIds.isEmpty {
                        ForEach(s.linkedResponseIds, id: \.self) { rid in
                            if let ans = block.answers.first(where: { $0.id == rid }) {
                                HStack {
                                    Text("↳ \(ans.text)")
                                        .font(.caption)
                                        .foregroundColor(.blue)

                                    Button {
                                        let ok = DatabaseManager.shared.execute(
                                            sql: "DELETE FROM links WHERE statement_id = ? AND response_id = ?;",
                                            bind: { stmt in
                                                sqlite3_bind_int(stmt, 1, Int32(s.id))
                                                sqlite3_bind_int(stmt, 2, Int32(rid))
                                            }
                                        )
                                        if ok {
                                            DispatchQueue.main.async {
                                                print("❌ Deleted link, scrollTarget=\(s.id)")
                                                scrollTarget = s.id
                                                reload()
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AnswerColumn: View {
    let block: BlockColumn
    @Binding var scrollTarget: Int?
    let reload: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Answers (\(block.answers.count))")
                .font(.headline)
            ForEach(block.answers) { a in
                Text(a.text)
                    .id(a.id)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    // Response → statement
                    .onDrag {
                        NSItemProvider(object: String(a.id) as NSString)
                    }
                    // Statement → response
                    .onDrop(of: [UTType.plainText.identifier], isTargeted: nil) { providers in
                        if let provider = providers.first {
                            _ = provider.loadObject(ofClass: String.self) { (str, _) in
                                if let str, let droppedId = Int(str) {
                                    print("🟣 Drop Statement→Response: statementId=\(droppedId), responseId=\(a.id)")
                                    let ok = DB.shared.insertLink(statementId: droppedId, responseId: a.id)
                                    if ok {
                                        DispatchQueue.main.async {
                                            print("📌 Setting scrollTarget=\(a.id)")
                                            scrollTarget = a.id
                                            reload()
                                        }
                                    }
                                }
                            }
                            return true
                        }
                        return false
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// ── Preview ──────────────────────────────────────────────────────────────────

#Preview {
    NavigationView {
        PairedPleadingsList(docID: "Roos.record.2007")
    }
}

