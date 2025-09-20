import SwiftUI

/// Right-hand panel wrapper for listing sentences.
/// Decoupled from IssuesScreen by defining its own Mode enum.
struct SentenceListPanel: View {
    enum Mode { case all, linked }

    var mode: Mode
    var selectedIssue: DBIssue?

    var body: some View {
        switch mode {
        case .all:
            AllSentencesPanel()
        case .linked:
            LinkedSentencesPanel(issue: selectedIssue) // existing panel takes DBIssue?
        }
    }
}

