// WebKitSafeMode.swift
// Compass

import Foundation

enum WebKitSafeMode {
    private static var didSet = false

    /// Call once, as early as possible (e.g., from ContentView.init()).
    static func enable() {
        guard !didSet else { return }
        setenv("WEBKIT_DISABLE_GPU_PROCESS", "1", 1)
        didSet = true
        NSLog("🧯 WebKitSafeMode enabled: WEBKIT_DISABLE_GPU_PROCESS=1")
    }
}
//
//  WebKitSafeMode.swift
//  Compass
//
//  Created by Peter Milligan on 13/09/2025.
//

