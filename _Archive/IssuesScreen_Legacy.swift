/*
 //  IssuesScreen_Legacy.swift
 //  Compass
 //
 //  Created by Peter Milligan on 20/09/2025.
 //

 import SwiftUI
 import SQLite3

 // MARK: - Screen
 struct IssuesScreen_Legacy: View {
     @State private var issues: [DBIssue] = []
     @State private var selectedIssue: DBIssue?
     @State private var showingAddSheet = false
     @State private var newTitle: String = ""

     enum Mode { case all, linked }
     @State private var mode: Mode = .all

     var body: some View {
         HStack(spacing: 0) {
             VStack(spacing: 0) {
                 IssuesNavPanel(
                     issues: issues,
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

             VStack(spacing: 0) {
                 Picker("Mode", selection: $mode) {
                     Text("All Sentences").tag(Mode.all)
                     Text("Linked Only").tag(Mode.linked)
                 }
                 .pickerStyle(.segmented)
                 .padding()

                 Divider()

                 SentenceListPanel(mode: mode, selectedIssue: selectedIssue)
             }
             .frame(maxWidth: .infinity, maxHeight: .infinity)
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
         .animation(.default, value: issues)
     }

     // MARK: - DB Path
     private var dbPath: String { "/Users/petermilligan/Dev/Compass/compass.db" }

     // MARK: - DB Load
     private func loadIssues() { … }

     // MARK: - DB Insert
     private func addIssue(title: String) { … }

     // MARK: - DB Delete (single index)
     private func deleteIssue(atIndex index: Int) { … }

     // MARK: - Reorder by ID
     private func reorderIssue(id: Int, delta: Int) { … }

     private func persistSortOrders(_ newOrder: [DBIssue]) { … }
 }
*/

