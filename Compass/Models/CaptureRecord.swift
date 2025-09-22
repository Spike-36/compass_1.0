//
//  CaptureRecord.swift
//  Compass
//
//  Phase 4a – baseline struct aligned with pipeline JSON
//

import Foundation

struct CaptureRecord: Codable, Identifiable {
    let doc_id: String
    let block_type: String   // "statement" | "answer"
    let block_number: Int
    let sentence_index: Int
    let text: String

    // Computed property for SwiftUI List etc.
    var id: String {
        "\(doc_id)-\(block_type)-\(block_number)-\(sentence_index)"
    }
}

