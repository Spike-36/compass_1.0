import Foundation

public struct DocumentIdentity: Equatable {
    public let docID: String
    public let docUID: UUID
    public let version: Int
    public let sha256: String
    public let type: String // "docx" | "pdf"
}

public enum IdentityBuilder {
    /// Compute identity and write a manifest shell + update /json/version-index.json
    public static func build(for fileURL: URL, jsonRoot: URL, type: String) throws -> DocumentIdentity {
        // 1) hash
        let sha = try Hashing.sha256(fileURL: fileURL)
        // 2) slug
        let docID = Slug.slugify(fileURL.lastPathComponent)
        // 3) uuidv5(name = first16 hex of sha256)
        let uid = UUIDv5.make(namespace: IDSpec.namespaceDocs, name: Hashing.first16OfSHA256Hex(sha))
        // 4) version
        let idxURL = jsonRoot.appendingPathComponent("version-index.json")
        var index = Versioning.load(from: idxURL)
        let version = Versioning.decideVersion(for: docID, sha256: sha, index: &index)
        try Versioning.save(index, to: idxURL)
        // 5) manifest shell
        let man = Manifest(doc_id: docID, doc_uid: uid, version: version, sha256: sha, type: type)
        let manURL = jsonRoot.appendingPathComponent("\(docID)@v\(version).manifest.json")
        try ManifestIO.write(man, to: manURL)

        return DocumentIdentity(docID: docID, docUID: uid, version: version, sha256: sha, type: type)
    }
}
//
//  ) DocumentIdentity.swift
//  Compass
//
//  Created by Peter Milligan on 12/09/2025.
//

