import Foundation

public struct Manifest: Codable, Equatable {
    public let doc_id: String
    public let doc_uid: UUID
    public let version: Int
    public let sha256: String
    public let type: String     // "docx" | "pdf"
    public let para_count: Int?
    public let sent_count: Int?
    public let anchors_checksum: String
    public let id_spec_version: Int

    public init(doc_id: String, doc_uid: UUID, version: Int, sha256: String, type: String,
                para_count: Int? = nil, sent_count: Int? = nil,
                anchors_checksum: String = "", id_spec_version: Int = IDSpec.version) {
        self.doc_id = doc_id
        self.doc_uid = doc_uid
        self.version = version
        self.sha256 = sha256
        self.type = type
        self.para_count = para_count
        self.sent_count = sent_count
        self.anchors_checksum = anchors_checksum
        self.id_spec_version = id_spec_version
    }
}

public enum ManifestIO {
    public static func write(_ manifest: Manifest, to url: URL) throws {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try enc.encode(manifest)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }

    public static func read(from url: URL) throws -> Manifest {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Manifest.self, from: data)
    }
}
//
//  Manifest.swift
//  Compass
//
//  Created by Peter Milligan on 12/09/2025.
//

