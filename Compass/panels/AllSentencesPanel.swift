import SwiftUI
import SQLite3

/// Flat row for "All Sentences"
private struct AllSentenceRow: Identifiable {
    let id: String
    let blockType: String
    let blockNumber: Int
    let sentenceIndex: Int
    let text: String
}

struct AllSentencesPanel: View {
    var docID: String = "Roos.record.2007"   // default for now

    @State private var rows: [AllSentenceRow] = []
    @State private var error: String?
    @State private var rowCount: Int = 0
    @State private var dbPath: String = "(bundle)"

    var body: some View {
        VStack(spacing: 0) {
            // Small debug header
            HStack(spacing: 8) {
                Text("DB:").font(.caption)
                    .foregroundColor(.secondary)

                Text(dbPath).font(.caption.monospaced())
                    .lineLimit(1).truncationMode(.middle)

                Spacer()

                Text("Rows: \(rowCount)")
                    .font(.caption.monospaced())
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)

            Divider()

            // Placeholder list — real DB hookup to come later
            List(rows) { row in
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.text)
                        .font(.body)
                    Text("Block \(row.blockNumber), idx \(row.sentenceIndex)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            loadSentences()
        }
    }

    // Temporary stub loader
    private func loadSentences() {
        // TODO: replace with SQLite fetch
        rows = [
            AllSentenceRow(id: "1", blockType: "statement", blockNumber: 1, sentenceIndex: 1, text: "Example sentence one."),
            AllSentenceRow(id: "2", blockType: "answer", blockNumber: 1, sentenceIndex: 2, text: "Example sentence two.")
        ]
        rowCount = rows.count
    }
}

#Preview {
    AllSentencesPanel()
}

