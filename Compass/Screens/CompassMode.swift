//
//  CompassMode.swift
//  Compass
//
//  Created by Pete on 20/09/2025.
//

import Foundation

/// The high-level modes of the app (top-level tabs).
enum CompassMode: String, CaseIterable, Identifiable {
    case issues = "Issues"
    case pleadings = "Pleadings"
    case pleadingsPDF = "Pleadings PDF"   // 👈 new mode
    case splitSentences = "Split Sentences"
    case sideBySide = "Side-by-Side"

    // Add more cases as the app grows:
    // case documents = "Documents"
    // case evidence = "Evidence"
    // case chronology = "Chronology"
    // case notes = "Notes"
    // case tasks = "Tasks"
    // case research = "Research"
    // case transcripts = "Transcripts"
    // case analysis = "Analysis"

    var id: String { rawValue }

    /// Display label for UI
    var label: String { rawValue }
}
