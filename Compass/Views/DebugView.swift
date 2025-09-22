//
//  DebugView.swift
//  Compass
//
//  Phase 4a – simple viewer for CaptureRecords
//

import SwiftUI

struct DebugView: View {
    let records: [CaptureRecord]   // <- just pass in the decoded array

    var body: some View {
        List(records) { record in
            VStack(alignment: .leading) {
                Text("\(record.block_type.capitalized) \(record.block_number).\(record.sentence_index)")
                    .font(.headline)
                Text(record.text)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    DebugView(records: [
        CaptureRecord(doc_id: "test",
                      block_type: "statement",
                      block_number: 1,
                      sentence_index: 1,
                      text: "This is a test record.")
    ])
}

