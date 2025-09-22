//
//  PleadingsPDFNavPanel.swift
//  Compass
//
//  Created by Pete on 21/09/2025.
//

import SwiftUI
import SQLite3

struct BlockRef: Identifiable {
    let id = UUID()
    let blockType: String
    let blockNumber: Int
}

struct PleadingsPDFNavPanel: View {
    let docID: String
    var onSelect: (String, Int) -> Void

    @State private var blocks: [BlockRef] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📑 PDF Navigation")
                .font(.headline)

            Divider()

            if blocks.isEmpty {
                Text("No blocks found.")
                    .foregroundColor(.secondary)
            } else {
                List(blocks) { block in
                    Button {
                        onSelect(block.blockType, block.blockNumber)
                    } label: {
                        Text(labelFor(block))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .onAppear {
            loadBlocks()
        }
    }

    private func loadBlocks() {
        guard let dbPath = Bundle.main.path(forResource: "compass", ofType: "db") else {
            print("❌ Database not found")
            return
        }

        var db: OpaquePointer?
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("❌ Failed to open DB")
            return
        }

        let query = """
        SELECT DISTINCT block_type, block_number
        FROM sentences
        WHERE doc_id = ?
        ORDER BY block_number, block_type;
        """

        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (docID as NSString).utf8String, -1, nil)

            var tmp: [BlockRef] = []
            while sqlite3_step(stmt) == SQLITE_ROW {
                if let cString = sqlite3_column_text(stmt, 0) {
                    let blockType = String(cString: cString)
                    let blockNumber = Int(sqlite3_column_int(stmt, 1))
                    tmp.append(BlockRef(blockType: blockType, blockNumber: blockNumber))
                }
            }
            blocks = tmp
        } else {
            print("❌ Failed to prepare query")
        }

        sqlite3_finalize(stmt)
        sqlite3_close(db)
    }

    private func labelFor(_ block: BlockRef) -> String {
        switch block.blockType.lowercased() {
        case "statement": return "Statement \(block.blockNumber)"
        case "answer": return "Answer \(block.blockNumber)"
        default: return "\(block.blockType.capitalized) \(block.blockNumber)"
        }
    }
}

// MARK: - Preview
#Preview {
    PleadingsPDFNavPanel(docID: "brown.record") { type, number in
        print("Selected \(type) \(number)")
    }
}

