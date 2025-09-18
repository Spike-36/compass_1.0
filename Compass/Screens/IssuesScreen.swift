//
//  IssuesScreen.swift
//  Compass
//

import SwiftUI
import SQLite3

// MARK: - Model
struct DBIssue: Identifiable, Hashable {
    let id: Int
    let title: String
    let sortOrder: Int
}

// MARK: - Screen
struct IssuesScreen: View {
    @State private var issues: [DBIssue] = []
    @State private var selectedIssue: DBIssue?
    @State private var showingAddSheet = false
    @State private var newTitle: String = ""

    var body: some View {
        HStack(spacing: 0) {
            // Left-hand Issues Nav
            VStack(spacing: 0) {
                IssuesNavPanel(
                    issues: $issues,
                    selectedIssue: $selectedIssue,
                    onDeleteIndex: deleteIssue(atIndex:),
                    onReorderByID: reorderIssue(id:delta:)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()

                Button(action: { showingAddSheet = true }) {
                    Label("New Issue", systemImage: "plus.circle.fill")
                }
                .padding(8)
            }
            .frame(width: 280)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Right-hand panel (stub for now)
            if let issue = selectedIssue {
                IssueSentencePanel(issue: issue)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack {
                    Text("Select an Issue")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Issues")
        .onAppear { loadIssues() }
        .sheet(isPresented: $showingAddSheet) {
            VStack(spacing: 16) {
                Text("New Issue").font(.headline)

                TextField("Title", text: $newTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 260)

                HStack {
                    Button("Cancel") {
                        showingAddSheet = false
                        newTitle = ""
                    }
                    Button("Add") {
                        guard !newTitle.isEmpty else { return }
                        addIssue(title: newTitle)
                        newTitle = ""
                        showingAddSheet = false
                        loadIssues()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(20)
            .frame(width: 320)
        }
        .animation(.default, value: issues) // animate order changes
    }

    // MARK: - DB Path
    private var dbPath: String { "/Users/petermilligan/Dev/Compass/compass.db" }

    // MARK: - DB Load
    private func loadIssues() {
        print("📥 loadIssues()")
        guard FileManager.default.fileExists(atPath: dbPath) else {
            print("❌ DB missing at \(dbPath)")
            return
        }

        var db: OpaquePointer?
        guard sqlite3_open(dbPath, &db) == SQLITE_OK, let db else {
            print("❌ Could not open DB at \(dbPath)")
            return
        }
        defer { sqlite3_close(db) }

        let query = "SELECT id, title, sort_order FROM issues ORDER BY sort_order, id"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK, let stmt else {
            print("❌ Prepare failed: \(String(cString: sqlite3_errmsg(db)))")
            return
        }
        defer { sqlite3_finalize(stmt) }

        var loaded: [DBIssue] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(stmt, 0))
            let title = String(cString: sqlite3_column_text(stmt, 1))
            let sortOrder = Int(sqlite3_column_int(stmt, 2))
            loaded.append(DBIssue(id: id, title: title, sortOrder: sortOrder))
        }
        issues = loaded
        print("✅ loaded \(issues.count) issue(s)")
    }

    // MARK: - DB Insert
    private func addIssue(title: String) {
        print("➕ addIssue('\(title)')")
        var db: OpaquePointer?
        guard sqlite3_open(dbPath, &db) == SQLITE_OK, let db else { return }
        defer { sqlite3_close(db) }

        let sql = """
            INSERT INTO issues (title, sort_order)
            VALUES (?, (SELECT COALESCE(MAX(sort_order), -1) + 1 FROM issues))
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else {
            print("❌ Prepare insert failed: \(String(cString: sqlite3_errmsg(db)))")
            return
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, title, -1, SQLITE_TRANSIENT)
        if sqlite3_step(stmt) != SQLITE_DONE {
            print("❌ Insert failed: \(String(cString: sqlite3_errmsg(db)))")
        } else {
            print("✅ Inserted")
        }
    }

    // MARK: - DB Delete (single index)
    private func deleteIssue(atIndex index: Int) {
        guard issues.indices.contains(index) else { return }
        let issue = issues[index]
        print("🗑️ deleteIssue id=\(issue.id) title='\(issue.title)'")
        var db: OpaquePointer?
        guard sqlite3_open(dbPath, &db) == SQLITE_OK, let db else { return }
        defer { sqlite3_close(db) }

        let sql = "DELETE FROM issues WHERE id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { return }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_int(stmt, 1, Int32(issue.id))
        if sqlite3_step(stmt) != SQLITE_DONE {
            print("❌ Delete failed: \(String(cString: sqlite3_errmsg(db)))")
        } else {
            print("✅ Deleted")
        }
        loadIssues()

        if selectedIssue?.id == issue.id {
            selectedIssue = nil
        }
    }

    // MARK: - Reorder by ID (fixes index drift)
    private func reorderIssue(id: Int, delta: Int) {
        guard let from = issues.firstIndex(where: { $0.id == id }) else {
            print("❌ reorderIssue: id \(id) not found")
            return
        }
        let to = from + delta
        guard issues.indices.contains(to) else {
            print("↔️ reorderIssue: out of bounds from \(from) -> \(to)")
            return
        }

        print("🔀 reorderIssue id=\(id) from=\(from) to=\(to)")

        var reordered = issues
        let item = reordered.remove(at: from)
        reordered.insert(item, at: to)

        persistSortOrders(reordered)
        issues = reordered
    }

    private func persistSortOrders(_ newOrder: [DBIssue]) {
        print("💾 persistSortOrders for \(newOrder.count) rows")
        var db: OpaquePointer?
        guard sqlite3_open(dbPath, &db) == SQLITE_OK, let db else {
            print("❌ Could not open DB for persistSortOrders")
            return
        }
        defer { sqlite3_close(db) }

        let sql = "UPDATE issues SET sort_order = ? WHERE id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else {
            print("❌ Prepare update failed: \(String(cString: sqlite3_errmsg(db)))")
            return
        }
        defer { sqlite3_finalize(stmt) }

        for (idx, issue) in newOrder.enumerated() {
            sqlite3_bind_int(stmt, 1, Int32(idx))
            sqlite3_bind_int(stmt, 2, Int32(issue.id))
            if sqlite3_step(stmt) != SQLITE_DONE {
                print("❌ Update sort_order failed for id \(issue.id): \(String(cString: sqlite3_errmsg(db)))")
            }
            sqlite3_reset(stmt)
        }
        print("✅ sort_order persisted")
    }
}

// MARK: - Left Panel (explicit buttons for macOS)
private struct IssuesNavPanel: View {
    @Binding var issues: [DBIssue]
    @Binding var selectedIssue: DBIssue?
    var onDeleteIndex: (Int) -> Void
    var onReorderByID: (Int, Int) -> Void   // (issueID, delta ±1)

    var body: some View {
        List(selection: $selectedIssue) {
            ForEach(issues, id: \.id) { issue in
                HStack {
                    Text(issue.title)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Spacer()

                    Button {
                        onReorderByID(issue.id, -1)
                    } label: {
                        Image(systemName: "arrow.up")
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.borderless)
                    .disabled(isFirst(issue))
                    .help("Move up")

                    Button {
                        onReorderByID(issue.id, +1)
                    } label: {
                        Image(systemName: "arrow.down")
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.borderless)
                    .disabled(isLast(issue))
                    .help("Move down")

                    Button {
                        if let idx = issues.firstIndex(where: { $0.id == issue.id }) {
                            onDeleteIndex(idx)
                        }
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.borderless)
                    .help("Delete")
                }
                .contentShape(Rectangle()) // make the whole row clickable for selection
                .tag(issue as DBIssue?)
            }
        }
        .listStyle(.sidebar)
    }

    private func isFirst(_ issue: DBIssue) -> Bool {
        issues.first?.id == issue.id
    }
    private func isLast(_ issue: DBIssue) -> Bool {
        issues.last?.id == issue.id
    }
}

// MARK: - Right Panel (stub)
private struct IssueSentencePanel: View {
    let issue: DBIssue

    var body: some View {
        VStack {
            Text("Sentences for issue:")
                .font(.headline)
            Text(issue.title)
                .font(.title2)
                .padding(.top)
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        IssuesScreen()
    }
}

