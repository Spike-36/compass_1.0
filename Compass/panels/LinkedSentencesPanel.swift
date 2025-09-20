import SwiftUI

struct LinkedSentencesPanel: View {
    var issue: DBIssue?

    var body: some View {
        if let issue = issue {
            Text("Linked sentences for issue: \(issue.title)")
        } else {
            Text("No issue selected")
        }
    }
}

