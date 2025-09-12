import Foundation

public enum IDSpec {
    public static let version: Int = 1
    // Padding
    public static let paraPad = 4   // p0001
    public static let sentPad = 2   // s01
    public static let pagePad = 3   // pg001
    public static let blockPad = 3  // b001
    // Scan quantization
    public static let xywhQuantum: Int = 5
    // Namespace UUID for UUIDv5 (pick once and never change)
    public static let namespaceDocs = UUID(uuidString: "9D8E2E9E-4C3B-49B5-A3E0-9C0B0E5B7E9F")!
    // Error codes
    public static let errManifestMismatch = "E-ID-MANIFEST-MISMATCH"
    public static let errDuplicateBytes   = "E-IMPORT-DUPLICATE-BYTES"
}
//
//  IDSpec.swift
//  Compass
//
//  Created by Peter Milligan on 12/09/2025.
//

