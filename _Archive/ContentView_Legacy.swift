//
//  ContentView_Legacy.swift
//  Compass
//
//  Created by Peter Milligan on 19/09/2025.
//

//
//  ContentView.swift
//  Compass
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView_Legacy
: View {
    // HTML preview (pipeline output)
    @State private var htmlURL: URL?
    // Selected source the user picked (DOCX / PDF)
    @State private var sourceURL: URL?
    // Last processed document id (used by Sentence View / Issues)
    @State private var lastDocID: String?

    // UI state
    @State private var status = "Ready"
    @State private var useDebugView = false
    @State private var showDBViewer = false
    @State private var showSentenceView = false
    @State private var showSBSView = false
    @State private var showPairedView = false
    @State private var showIssuesView = false   // <-- new

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                Toggle("Debug WebView", isOn: $useDebugView)
                    .toggleStyle(.switch)
                    .help("ON: show inline test page. OFF: show pipeline output")

                if useDebugView {
                    Button("DB Viewer") { showDBViewer = true }
                        .help("Open a quick, read-only view of the bundled compass.db")
                }

                Divider().frame(height: 18)

                Text(status)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                // Open Sentence View (enabled after pipeline produced a doc id)
                Button("Sentence View…") { showSentenceView = true }
                    .disabled(lastDocID == nil)

                Button("Side-by-Side…") { showSBSView = true }
                    .disabled(lastDocID == nil)

                Button("Paired Pleadings…") { showPairedView = true }
                    .disabled(lastDocID == nil)

                Button("Issues…") { showIssuesView = true }   // <-- new button
                    .disabled(lastDocID == nil)

                Button("Choose…") { chooseSource() }

                if let url = htmlURL, !useDebugView {
                    Button("Open") { NSWorkspace.shared.open(url) }
                    Button("Reveal") { NSWorkspace.shared.activateFileViewerSelecting([url]) }
                }

                Button("Re-run Demo") { runPipelineIfPossible() }
                    .keyboardShortcut("r", modifiers: [.command])
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Viewer
            Group {
                if useDebugView {
                    InlineProbeView()
                } else {
                    LoggingWebView(url: htmlURL)
                }
            }
            .frame(minWidth: 800, minHeight: 600)

            if let src = sourceURL, !useDebugView {
                Divider()
                HStack {
                    Text("Source: \(src.path)")
                        .font(.caption.monospaced())
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                }
                .padding([.horizontal, .bottom], 8)
            }
        }
        .onAppear {
            if sourceURL == nil { chooseSource() }
        }
        .onChange(of: useDebugView) { _, newValue in
            if newValue {
                status = "Debug mode: InlineProbeView"
            } else if let url = htmlURL {
                status = "Loaded → \(url.lastPathComponent)"
            } else {
                status = "Pipeline mode (no HTML yet)"
            }
        }
        // DB Viewer sheet
        .sheet(isPresented: $showDBViewer) {
            NavigationView { DatabaseViewer() }
                .frame(minWidth: 700, minHeight: 500)
        }
        // Sentence View sheet
        .sheet(isPresented: $showSentenceView) {
            if let id = lastDocID {
                NavigationView { PleadingsList(docID: id) }
                    .frame(minWidth: 700, minHeight: 500)
            } else {
                Text("No document loaded yet.")
                    .frame(minWidth: 400, minHeight: 200)
            }
        }
        // Side-by-Side View sheet
        .sheet(isPresented: $showSBSView) {
            if let id = lastDocID {
                NavigationView { PleadingsListSBS(docID: id) }
                    .frame(minWidth: 1200, minHeight: 700)
            } else {
                Text("No document loaded yet.")
                    .frame(minWidth: 400, minHeight: 200)
            }
        }
        // Paired Pleadings View sheet
        .sheet(isPresented: $showPairedView) {
            if let id = lastDocID {
                NavigationView { PairedPleadingsList(docID: id) }
                    .frame(minWidth: 1000, minHeight: 700)
            } else {
                Text("No document loaded yet.")
                    .frame(minWidth: 400, minHeight: 200)
            }
        }
        // Issues View sheet
        .sheet(isPresented: $showIssuesView) {
            if let _ = lastDocID {
                NavigationView { IssuesScreen() }   // currently stubbed
                    .frame(minWidth: 1200, minHeight: 700)
            } else {
                Text("No document loaded yet.")
                    .frame(minWidth: 400, minHeight: 200)
            }
        }
    }

    // MARK: - Actions

    private func chooseSource() {
        let panel = NSOpenPanel()
        panel.title = "Choose a document"
        panel.allowedContentTypes = [UTType(filenameExtension: "docx")!, .pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.begin { resp in
            if resp == .OK, let url = panel.url {
                sourceURL = url
                runPipelineIfPossible()
            } else {
                status = "No file selected"
            }
        }
    }

    private func runPipelineIfPossible() {
        guard let src = sourceURL else {
            status = "Select a DOCX/PDF first"
            htmlURL = nil
            lastDocID = nil
            return
        }
        status = "Processing…"
        do {
            let res = try DocxPipeline.run(input: src)
            htmlURL = res.htmlURL
            lastDocID = res.docID
            status = "Loaded \(res.docID)@v\(res.version) → \(res.htmlURL.lastPathComponent)"
        } catch {
            htmlURL = nil
            lastDocID = nil
            status = "Error: \(error.localizedDescription)"
        }
    }
}

