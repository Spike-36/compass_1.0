import Foundation

public enum ManifestUpdate {
    /// Call after export to fill counts + checksum
    public static func finalize(docID: String, version: Int, jsonRoot: URL, result: HTMLExportResult) throws {
        let manURL = jsonRoot.appendingPathComponent("\(docID)@v\(version).manifest.json")
        var manifest = try ManifestIO.read(from: manURL)
        let checksum = AnchorChecksum.compute(result.anchors)
        manifest = Manifest(doc_id: manifest.doc_id,
                            doc_uid: manifest.doc_uid,
                            version: manifest.version,
                            sha256: manifest.sha256,
                            type: manifest.type,
                            para_count: result.paraCount,
                            sent_count: result.sentCount,
                            anchors_checksum: checksum,
                            id_spec_version: manifest.id_spec_version)
        try ManifestIO.write(manifest, to: manURL)
    }
}
//
//  ManifestUpdate.swift
//  Compass
//
//  Created by Peter Milligan on 12/09/2025.
//

