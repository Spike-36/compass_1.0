import Foundation
import CryptoKit

public enum AnchorChecksum {
    /// Deterministic checksum of all anchors, newline-joined.
    public static func compute(_ anchors: [String]) -> String {
        let joined = anchors.joined(separator: "\n")
        let digest = SHA256.hash(data: joined.data(using: .utf8)!)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
//
//  AnchorChecksum.swift
//  Compass
//
//  Created by Peter Milligan on 12/09/2025.
//

