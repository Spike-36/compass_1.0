// DatabaseViewer.swift (LIVE DB)
import SwiftUI
import SQLite3
import AppKit

struct SentenceRow: Identifiable {
    let id = UUID()
    let blockType: String
    let blockNumber: Int
    let sentenceIndex: Int
    let text: String
}

struct ErrorWrap: Identifiable { let id = UUID(); let message: String }

private enum DBPrefs {
    static let key = "LiveDBPath"
    static var savedPath: String? {
        get { UserDefaults.standard.string(forKey: key) }
        set { UserDefaults.standard.setValue(newValue, forKey: key) }
    }
}

/// Try a sensible default for your dev box
private func defaultDBPath() -> String {
    let home = FileManager.default.homeDirectoryForCurrentUser
    return home.appendingPathComponent("Dev/Compass/compass.db").path
}

struct DatabaseViewer: View {
    @State private var rows: [SentenceRow] = []
    @State private var errorWrap: ErrorWrap?
    @State private var dbPath: String = DBPrefs.savedPath ?? defaultDBPath()
    @State private var rowCount: Int = 0

    var body: some View {
        VStack(spacing: 10) {
            // Controls
            HStack(spacing: 8) {
                Text("DB:").font(.caption).foregroundColor(.secondary)
                TextField("/path/to/compass.db", text: $dbPath)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { saveAndReload() }
                    .frame(minWidth: 420)

                Button("Choose…") { chooseDB() }
                Button("Reload") { loadData() }
                Spacer()
                Text("Rows: \(rowCount)").font(.caption.monospaced()).foregroundColor(.secondary)
            }

            if let e = errorWrap {
                Text(e.message).foregroundColor(.red).font(.caption)
            }

            List(rows) { row in
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.text)
                    Text("\(row.blockType) \(row.blockNumber).\(row.sentenceIndex)")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .navigationTitle("DB Viewer (Live)")
        .onAppear(perform: loadData)
        .alert(item: $errorWrap) { e in
            Alert(title: Text("Error"), message: Text(e.message), dismissButton: .default(Text("OK")))
        }
    }

    private func saveAndReload() {
        DBPrefs.savedPath = dbPath
        loadData()
    }

    private func chooseDB() {
        let p = NSOpenPanel()
        p.canChooseFiles = true
        p.canChooseDirectories = false
        p.allowsMultipleSelection = false
        p.allowedFileTypes = ["db", "sqlite", "sqlite3"]
        p.title = "Select compass.db"
        p.begin { resp in
            if resp == .OK, let url = p.url {
                dbPath = url.path
                saveAndReload()
            }
        }
    }

    private func loadData() {
        errorWrap = nil
        rows.removeAll()

        guard FileManager.default.fileExists(atPath: dbPath) else {
            errorWrap = ErrorWrap(message: "DB not found at \(dbPath)")
            rowCount = 0
            return
        }

        var db: OpaquePointer?
        guard sqlite3_open(dbPath, &db) == SQLITE_OK, let db else {
            errorWrap = ErrorWrap(message: "Failed to open DB at \(dbPath)")
            rowCount = 0
            return
        }
        defer { sqlite3_close(db) }

        let sql = """
        SELECT block_type, block_number, sentence_index, text
        FROM sentences
        ORDER BY block_number, block_type, sentence_index
        """

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else {
            errorWrap = ErrorWrap(message: "Prepare failed.")
            rowCount = 0
            return
        }
        defer { sqlite3_finalize(stmt) }

        var out: [SentenceRow] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let bt = String(cString: sqlite3_column_text(stmt, 0))
            let bn = Int(sqlite3_column_int(stmt, 1))
            let si = Int(sqlite3_column_int(stmt, 2))
            let tx = String(cString: sqlite3_column_text(stmt, 3))
            out.append(SentenceRow(blockType: bt, blockNumber: bn, sentenceIndex: si, text: tx))
        }

        rows = out
        rowCount = out.count
    }
}

