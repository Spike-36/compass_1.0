import Foundation
import SQLite3

/// High-level DAO for `links` table.
/// All actual SQLite work is delegated to `DatabaseManager`.
final class DB {
    static let shared = DB()

    private init() {
        createTables()
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
        DatabaseManager.shared.execute(sql: createLinksSQL)
    }

    // MARK: - Insert Link
    func insertLink(statementId: Int, responseId: Int) -> Bool {
        DatabaseManager.shared.execute(
            sql: "INSERT OR IGNORE INTO links (statement_id, response_id) VALUES (?, ?);",
            bind: { stmt in
                sqlite3_bind_int(stmt, 1, Int32(statementId))
                sqlite3_bind_int(stmt, 2, Int32(responseId))
            }
        )
    }

    // MARK: - Delete Link
    func deleteLink(id: Int) -> Bool {
        DatabaseManager.shared.execute(
            sql: "DELETE FROM links WHERE id = ?;",
            bind: { stmt in
                sqlite3_bind_int(stmt, 1, Int32(id))
            }
        )
    }

    // MARK: - Fetch Links for a Statement
    func fetchLinks(forStatement id: Int) -> [(id: Int, responseId: Int)] {
        var results: [(id: Int, responseId: Int)] = []

        DatabaseManager.shared.query(
            sql: "SELECT id, response_id FROM links WHERE statement_id = ?;",
            bind: { stmt in
                sqlite3_bind_int(stmt, 1, Int32(id))
            },
            row: { stmt in
                let linkId = Int(sqlite3_column_int(stmt, 0))
                let responseId = Int(sqlite3_column_int(stmt, 1))
                results.append((id: linkId, responseId: responseId))
            }
        )

        return results
    }
}
