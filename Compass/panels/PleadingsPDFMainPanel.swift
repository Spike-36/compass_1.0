//
//  PleadingsPDFMainPanel.swift
//  Compass
//
//  Created by Pete on 21/09/2025.
//

import SwiftUI
import PDFKit   // 👈 needed here for PDFView

struct PleadingsPDFMainPanel: View {
    // 👇 Start with nothing — will update when notification arrives
    @State private var pdfURL: URL? = nil

    // Keep one PDFView instance alive, fully configured
    private let pdfView = PDFKitView.makePDFView()

    var body: some View {
        VStack {
            HStack {
                Button("⏮ First Page") { pdfView.goToFirstPage(nil) }
                Button("◀︎ Prev") { pdfView.goToPreviousPage(nil) }
                Button("Next ▶︎") { pdfView.goToNextPage(nil) }
                Button("Last Page ⏭") { pdfView.goToLastPage(nil) }
                Spacer()
            }
            .padding()

            if let url = pdfURL {
                PDFKitView(pdfView: pdfView, url: url)
                    .frame(minWidth: 1000, minHeight: 700)
            } else {
                Text("⚠️ No PDF selected")
                    .font(.headline)
                    .frame(minWidth: 400, minHeight: 200)
            }
        }
        // 👇 Listen for conversion completion and swap in new file
        .onReceive(NotificationCenter.default.publisher(for: .OpenConvertedPDF)) { note in
            if let url = note.userInfo?["url"] as? URL {
                print("📥 PleadingsPDFMainPanel received PDF: \(url.path)")
                pdfURL = url
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PleadingsPDFMainPanel()
}

