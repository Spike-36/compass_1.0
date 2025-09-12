//
//  Hashing.swift
//  Compass
//
//  Created by Peter Milligan on 12/09/2025.
//

import Foundation
import CryptoKit

public enum Hashing {
    public static func sha256(fileURL: URL) throws -> String {
        let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
        return sha256(data: data)
    }

    public static func sha256(data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    public static func first16OfSHA256Hex(_ hex: String) -> String {
        String(hex.prefix(16))
    }
}
