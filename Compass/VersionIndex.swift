import Foundation

/// Stored as /json/version-index.json per case; maps doc_id -> [(version, sha256)]
public struct VersionIndex: Codable {
    public struct Entry: Codable { public let version: Int; public let sha256: String }
    public var docs: [String: [Entry]] = [:]
    public init() {}
}

public enum Versioning {
    public static func load(from url: URL) -> VersionIndex {
        guard let data = try? Data(contentsOf: url) else { return VersionIndex() }
        return (try? JSONDecoder().decode(VersionIndex.self, from: data)) ?? VersionIndex()
    }

    public static func save(_ idx: VersionIndex, to url: URL) throws {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try enc.encode(idx)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }

    /// Reuse version if sha256 already present; otherwise assign max+1 and append.
    public static func decideVersion(for docID: String, sha256: String, index: inout VersionIndex) -> Int {
        var entries = index.docs[docID] ?? []
        if let e = entries.first(where: { $0.sha256 == sha256 }) { return e.version }
        let next = (entries.map { $0.version }.max() ?? 0) + 1
        entries.append(.init(version: next, sha256: sha256))
        entries.sort { $0.version < $1.version }
        index.docs[docID] = entries
        return next
    }
}
//
//  VersionIndex.swift
//  Compass
//
//  Created by Peter Milligan on 12/09/2025.
//

