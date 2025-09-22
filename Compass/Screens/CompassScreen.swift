//
//  CompassScreen.swift
//  Compass
//

import SwiftUI

struct CompassScreen: View {
    @State private var mode: CompassMode
    @State private var importStatus: String = ""        // track docx import status

    // Keep the nav panel width in one place so we can reuse it
    private let navPanelWidth: CGFloat = 280

    // 🔑 Custom init so ContentView can set the starting mode
    init(initialMode: CompassMode = .pleadings) {
        _mode = State(initialValue: initialMode)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Mode switcher + heading on the same row
            HStack(alignment: .firstTextBaseline) {
                Picker("View", selection: $mode) {
                    ForEach(CompassMode.allCases) { m in
                        Text(m.label).tag(m)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 140, height: 28)  // 🔒 lock size so it doesn’t jiggle
                .alignmentGuide(.firstTextBaseline) { d in d[.firstTextBaseline] }

                Spacer()

                // 📂 Import button
                Button("📂 Import .docx") {
                    pickDocxFile()
                }
                .frame(width: 140, height: 28)

                Text(importStatus)
                    .font(.caption)
                    .foregroundColor(.gray)

                // Reserve nav panel width so heading lines up with main panel
                Spacer().frame(width: navPanelWidth)

                Text(mode.label)
                    .font(.system(size: 25, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)

            Divider()

            // Split view (left nav, right main)
            HStack(spacing: 0) {
                ModeNavigator.navPanel(for: mode)
                    .frame(width: navPanelWidth)
                    .background(Color(nsColor: .windowBackgroundColor))

                Divider()

                ModeNavigator.mainPanel(for: mode)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Compass")
    }

    private func pickDocxFile() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["docx"]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            // 🔌 Hook into DocxImportManager
            DocxImportManager.handleImport(url: url) { status in
                DispatchQueue.main.async {
                    self.importStatus = status
                }
            }
        } else {
            importStatus = "❌ Cancelled"
        }
    }
}

#Preview {
    CompassScreen(initialMode: .pleadingsPDF)   // 👈 now you can preview starting in PDF mode
}

