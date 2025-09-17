import Foundation
import SQLite3

// Keep this at top-level
let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

final class DatabaseManager {
    static let shared = DatabaseManager()

    private var db: OpaquePointer?
    // Serial queue guarantees single in-process writer / ordered access
    private let dbQueue = DispatchQueue(label: "Compass.DatabaseQueue", qos: .userInitiated)

    private init() {
        open()
    }

    deinit {
        close()
    }

    private func dbPath() -> String {
        FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Dev/Compass/compass.db")
            .path
    }

    private func open() {
        let path = dbPath()
        if sqlite3_open(path, &db) != SQLITE_OK {
            let msg = db.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
            print("❌ Failed to open database at \(path): \(msg)")
            return
        }
        print("✅ Database opened at \(path)")

        // WAL allows many readers + 1 writer
        execPragma("PRAGMA journal_mode=WAL;")
        // Give SQLite time to wait on locks (3s)
        execPragma("PRAGMA busy_timeout=3000;")
        // Keep fsyncs reasonable for WAL; safer than OFF, faster than FULL
        execPragma("PRAGMA synchronous=NORMAL;")
        // Enforce FKs so we fail fast on bad IDs
        execPragma("PRAGMA foreign_keys=ON;")
    }

    private func execPragma(_ sql: String) {
        guard let db else { return }
        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
            let msg = String(cString: sqlite3_errmsg(db))
            print("⚠️ PRAGMA failed: \(sql) → \(msg)")
        } else {
            print("✅ \(sql)")
        }
    }

    private func close() {
        guard let db else { return }
        // Ensure no statements are left unfinalized before close
        let rc = sqlite3_close(db)
        if rc != SQLITE_OK {
            let msg = String(cString: sqlite3_errmsg(db))
            print("⚠️ sqlite3_close returned \(rc): \(msg)")
        } else {
            print("✅ Database closed")
        }
        self.db = nil
    }

    // MARK: - Execute (INSERT/UPDATE/DELETE/DDL)
    @discardableResult
    func execute(sql: String, bind: ((OpaquePointer?) -> Void)? = nil) -> Bool {
        var success = false
        dbQueue.sync {
            guard let db else { return }
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt {
                defer { sqlite3_finalize(stmt) }
                bind?(stmt)
                let step = sqlite3_step(stmt)
                if step == SQLITE_DONE {
                    success = true
                } else {
                    let code = sqlite3_errcode(db)
                    let msg  = String(cString: sqlite3_errmsg(db))
                    print("❌ Execute failed [code \(code)]: \(msg) [SQL: \(sql)]")
                }
            } else {
                let msg = String(cString: sqlite3_errmsg(db))
                print("❌ Failed to prepare: \(msg) [SQL: \(sql)]")
            }
        }
        return success
    }

    // MARK: - Query (SELECT)
    func query(
        sql: String,
        bind: ((OpaquePointer?) -> Void)? = nil,
        row: (OpaquePointer?) -> Void
    ) {
        dbQueue.sync {
            guard let db else { return }
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else {
                let msg = String(cString: sqlite3_errmsg(db))
                print("❌ Failed to prepare query: \(msg) [SQL: \(sql)]")
                return
            }
            defer { sqlite3_finalize(stmt) }

            bind?(stmt)

            while sqlite3_step(stmt) == SQLITE_ROW {
                row(stmt)
            }
        }
    }

    func getLastInsertRowId() -> Int {
        var id = 0
        dbQueue.sync {
            if let db {
                id = Int(sqlite3_last_insert_rowid(db))
            }
        }
        return id
    }
}

