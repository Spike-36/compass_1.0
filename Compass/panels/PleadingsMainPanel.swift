//
//  PleadingsMainPanel.swift
//  Compass
//
//  Created by Pete on 20/09/2025.
//

import SwiftUI

struct PleadingsMainPanel: View {
    // Look up the HTML from the app bundle
    private let htmlURL = Bundle.main.url(
        forResource: "Roos.record.2007", // filename (no extension)
        withExtension: "html"
    )

    var body: some View {
        VStack {
            if let url = htmlURL {
                LoggingWebView(url: url)
                    .frame(minWidth: 1000, minHeight: 700)
            } else {
                Text("⚠️ Could not load Roos.record.2007.html from bundle")
                    .font(.headline)
                    .frame(minWidth: 400, minHeight: 200)
            }
        }
    }
}

