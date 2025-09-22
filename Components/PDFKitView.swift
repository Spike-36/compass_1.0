//
//  PDFKitView.swift
//  Compass
//
//  A reusable SwiftUI wrapper around PDFKit’s PDFView (macOS version)
//

import SwiftUI
import PDFKit

/// Wraps PDFKit’s PDFView for use inside SwiftUI
struct PDFKitView: NSViewRepresentable {
    let pdfView: PDFView
    let url: URL?

    func makeNSView(context: Context) -> PDFView {
        // Always return the configured instance we were given
        configure(pdfView, with: url)
        return pdfView
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        configure(nsView, with: url)
    }

    // MARK: - Centralized setup
    private func configure(_ view: PDFView, with url: URL?) {
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = NSColor.windowBackgroundColor

        if let url = url {
            view.document = PDFDocument(url: url)
        } else {
            view.document = nil
        }
    }
}

// MARK: - Factory for consistent PDFView creation
extension PDFKitView {
    static func makePDFView() -> PDFView {
        let v = PDFView()
        v.autoScales = true
        v.displayMode = .singlePageContinuous
        v.displayDirection = .vertical
        v.backgroundColor = NSColor.windowBackgroundColor
        return v
    }
}

