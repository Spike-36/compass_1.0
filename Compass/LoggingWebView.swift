// LoggingWebView.swift
// Compass

import SwiftUI
import WebKit

final class WKNavLogger: NSObject, WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation nav: WKNavigation!) { print("📡 didStartProvisionalNavigation") }
    func webView(_ webView: WKWebView, didCommit nav: WKNavigation!) { print("📡 didCommit") }
    func webView(_ webView: WKWebView, didFinish nav: WKNavigation!) { print("✅ didFinish") }
    func webView(_ webView: WKWebView, didFail nav: WKNavigation!, withError error: Error) { print("❌ didFail:", error.localizedDescription) }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation nav: WKNavigation!, withError error: Error) { print("❌ didFailProvisional:", error.localizedDescription) }
}

struct LoggingWebView: NSViewRepresentable {
    let url: URL?
    var disableJS: Bool = false
    var stripCSS: Bool = false

    private static let INLINE_FALLBACK = """
    <!doctype html><meta charset="utf-8">
    <title>Inline Fallback</title>
    <style>
      body { font: 16px -apple-system, system-ui; margin: 24px; color:#fff; background:#121212 }
      .box { padding:16px; border-radius:8px; background:#2b2b2b; border:1px solid #444 }
      .sent { background:#fff59d; padding:2px 4px; border-radius:3px }
    </style>
    <article class="box">
      <h1>Inline Fallback</h1>
      <p>If you see this, the file read failed or HTML was empty.</p>
      <p><span class="sent">Tap me</span> to prove CSS/JS render.</p>
      <script>
        addEventListener('click', e => {
          if (e.target.classList.contains('sent')) e.target.classList.toggle('on');
        });
      </script>
    </article>
    """

    func makeNSView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.websiteDataStore = .nonPersistent()
        cfg.mediaTypesRequiringUserActionForPlayback = .all
        if #available(macOS 11.0, *) {
            cfg.defaultWebpagePreferences.allowsContentJavaScript = !disableJS
        } else {
            cfg.preferences.javaScriptEnabled = !disableJS
        }
        let wv = WKWebView(frame: .zero, configuration: cfg)
        if #available(macOS 13.3, *) { wv.isInspectable = true }
        wv.navigationDelegate = context.coordinator
        return wv
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        guard let url else {
            print("ℹ️ url is nil → inline fallback")
            webView.loadHTMLString(Self.INLINE_FALLBACK, baseURL: nil)
            return
        }
        do {
            var html = try String(contentsOf: url, encoding: .utf8)
            let originalCount = html.count
            if stripCSS {
                html = html.replacingOccurrences(of: "(?is)<style\\b.*?</style>", with: "", options: .regularExpression)
                html = html.replacingOccurrences(of: "(?is)<link\\b[^>]*rel=[\"']?stylesheet[\"']?[^>]*>", with: "", options: .regularExpression)
            }
            let trimmed = html.trimmingCharacters(in: .whitespacesAndNewlines)
            print("ℹ️ read \(originalCount) chars (\(stripCSS ? "CSS stripped" : "raw")) from \(url.path)")
            if trimmed.isEmpty {
                webView.loadHTMLString(Self.INLINE_FALLBACK, baseURL: nil)
            } else {
                webView.loadHTMLString(trimmed, baseURL: url.deletingLastPathComponent())
            }
        } catch {
            print("❌ read error:", error.localizedDescription)
            webView.loadHTMLString(Self.INLINE_FALLBACK, baseURL: nil)
        }
    }

    func makeCoordinator() -> WKNavLogger { WKNavLogger() }
}

