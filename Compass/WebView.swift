// WebView.swift  (REPLACE THE WHOLE FILE)
import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    let url: URL?

    func makeNSView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        let wv = WKWebView(frame: .zero, configuration: cfg)
        wv.navigationDelegate = context.coordinator
        wv.setValue(false, forKey: "drawsBackground") // keep dark bg from page
        return wv
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // 1) If we have a file, load it with explicit read access (this is the key fix)
        if let url {
            let dir = url.deletingLastPathComponent()
            DispatchQueue.main.async {
                webView.loadFileURL(url, allowingReadAccessTo: dir)
            }
            return
        }

        // 2) Fallback inline HTML so the view never looks blank
        let html = """
        <!doctype html><html><head><meta charset="utf-8">
        <meta name="color-scheme" content="dark light">
        <title>Compass — no file</title>
        <style>
          body { font: 16px -apple-system, system-ui, Helvetica, Arial; margin: 24px; color:#fff; background:#121212; }
        </style>
        </head><body>
          <p><em>No HTML file provided.</em></p>
        </body></html>
        """
        DispatchQueue.main.async {
            webView.loadHTMLString(html, baseURL: nil)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("⚠️ WKWebView didFail:", error.localizedDescription)
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("⚠️ WKWebView didFailProvisional:", error.localizedDescription)
        }
    }
}

