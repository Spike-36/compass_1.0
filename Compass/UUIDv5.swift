import Foundation
import CryptoKit

/// UUID v5 (name-based, SHA-1) per RFC 4122.
public enum UUIDv5 {
    public static func make(namespace: UUID, name: String) -> UUID {
        // namespace bytes + name bytes
        var ns = namespace.uuid
        var bytes = withUnsafeBytes(of: ns) { Data($0) }
        bytes.append(name.data(using: .utf8)!)

        // SHA-1 digest (20 bytes)
        let digest = Insecure.SHA1.hash(data: bytes)

        // Take first 16 bytes as base UUID
        var b = Array(digest)[0..<16]  // Slice<UInt8>
        var arr = Array(b)             // [UInt8] of length 16

        // Set version (5) and variant (RFC 4122)
        arr[6] = (arr[6] & 0x0F) | 0x50  // 0b0101xxxx -> version 5
        arr[8] = (arr[8] & 0x3F) | 0x80  // 10xxxxxx   -> variant RFC 4122

        // Build uuid_t tuple
        let u: uuid_t = (arr[0], arr[1], arr[2], arr[3], arr[4], arr[5], arr[6], arr[7],
                         arr[8], arr[9], arr[10], arr[11], arr[12], arr[13], arr[14], arr[15])

        return UUID(uuid: u)
    }
}

