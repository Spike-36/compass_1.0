//  ContentView.swift
//  Compass

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var htmlURL: URL?
    @State private var status = "Ready"
    @State private var useDebugView = false   // ON = inline test page, OFF = pipeline output
    @State private var sourceURL: URL?        // user-selected DOCX/PDF

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                Toggle("Debug WebView", isOn: $useDebugView)
                    .toggleStyle(.switch)
                    .help("ON: show inline test page. OFF: show pipeline output")

                Divider().frame(height: 18)

                Text(status)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

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
            // Prompt to pick a file on first launch
            if sourceURL == nil { chooseSource() }
        }
        // keep the status hint in sync when toggling views (new two-arg version avoids deprecation)
        .onChange(of: useDebugView) { _, newValue in
            if newValue {
                status = "Debug mode: InlineProbeView"
            } else if let url = htmlURL {
                status = "Loaded → \(url.lastPathComponent)"
            } else {
                status = "Pipeline mode (no HTML yet)"
            }
        }
    }

    // MARK: - Actions

    private func chooseSource() {
        let panel = NSOpenPanel()
        panel.title = "Choose a document"
        panel.allowedContentTypes = [
            UTType(filenameExtension: "docx")!,
            .pdf
        ]
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
            return
        }
        status = "Processing…"
        do {
            let res = try DocxPipeline.run(input: src)
            htmlURL = res.htmlURL
            status = "Loaded \(res.docID)@v\(res.version) → \(res.htmlURL.lastPathComponent)"
        } catch {
            htmlURL = nil
            status = "Error: \(error.localizedDescription)"
        }
    }
}

