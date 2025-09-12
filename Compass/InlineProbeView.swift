// InlineProbeView.swift
// Compass

import SwiftUI
import WebKit

struct InlineProbeView: NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView {
        let wv = WKWebView()
        wv.loadHTMLString(Self.html, baseURL: nil)
        return wv
    }
    func updateNSView(_ nsView: WKWebView, context: Context) { }

    private static let html = """
    <!doctype html><meta charset="utf-8">
    <style>
      body { margin:0; background: #111; color: #fff; font: 28px -apple-system, system-ui; }
      .wrap { padding: 40px }
      .card { background:#1f6feb; padding:24px; border-radius:16px; }
    </style>
    <div class="wrap">
      <div class="card">✅ InlineProbeView is rendering inside WKWebView.</div>
      <p style="margin-top:24px">If you can see this, the WebView itself is fine.</p>
    </div>
    """
}

//
//  InlineProbeView.swift
//  Compass
//
//  Created by Peter Milligan on 12/09/2025.
//

