import Foundation
import SQLite3

final class DB {
    static let shared = DB()
    private var db: OpaquePointer?

    private init() {
        openDB()
        createTables()
    }

    // MARK: - Open DB
    private func openDB() {
        let fileURL = try! FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("app.sqlite")

        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("❌ Unable to open database.")
        } else {
            print("✅ Database opened at \(fileURL.path)")
        }
    }

    // MARK: - Create Tables
    private func createTables() {
        let createLinksSQL = """
        CREATE TABLE IF NOT EXISTS links (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            statement_id INTEGER NOT NULL,
            response_id INTEGER NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(statement_id, response_id),
            FOREIGN KEY(statement_id) REFERENCES sentences(id),
            FOREIGN KEY(response_id) REFERENCES sentences(id)
        );
        """

        execute(sql: createLinksSQL)
    }

    // MARK: - Execute Helper
    private func execute(sql: String) {
        var errMsg: UnsafeMutablePointer<Int8>?
        if sqlite3_exec(db, sql, nil, nil, &errMsg) != SQLITE_OK {
            let msg = String(cString: errMsg!)
            print("❌ SQL error: \(msg)")
        }
    }

    // MARK: - Insert Link
    func insertLink(statementId: Int, responseId: Int) -> Bool {
        let sql = "INSERT OR IGNORE INTO links (statement_id, response_id) VALUES (?, ?);"
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            print("❌ Prepare failed.")
            return false
        }

        sqlite3_bind_int(stmt, 1, Int32(statementId))
        sqlite3_bind_int(stmt, 2, Int32(responseId))

        if sqlite3_step(stmt) == SQLITE_DONE {
            sqlite3_finalize(stmt)
            return true
        } else {
            print("❌ Insert failed.")
            sqlite3_finalize(stmt)
            return false
        }
    }

    // MARK: - Delete Link
    func deleteLink(id: Int) -> Bool {
        let sql = "DELETE FROM links WHERE id = ?;"
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            return false
        }

        sqlite3_bind_int(stmt, 1, Int32(id))

        if sqlite3_step(stmt) == SQLITE_DONE {
            sqlite3_finalize(stmt)
            return true
        } else {
            sqlite3_finalize(stmt)
            return false
        }
    }

    // MARK: - Fetch Links for a Statement
    func fetchLinks(forStatement id: Int) -> [(id: Int, responseId: Int)] {
        let sql = "SELECT id, response_id FROM links WHERE statement_id = ?;"
        var stmt: OpaquePointer?
        var results: [(id: Int, responseId: Int)] = []

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(id))
            while sqlite3_step(stmt) == SQLITE_ROW {
                let linkId = Int(sqlite3_column_int(stmt, 0))
                let responseId = Int(sqlite3_column_int(stmt, 1))
                results.append((id: linkId, responseId: responseId))
            }
        }
        sqlite3_finalize(stmt)
        return results
    }
}
