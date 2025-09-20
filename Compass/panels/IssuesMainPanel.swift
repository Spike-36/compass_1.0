import SwiftUI

struct IssuesMainPanel: View {
    // Stub property for now
    var issue: String? = nil

    var body: some View {
        VStack {
            Text("📝 IssuesMainPanel (stub)")
                .font(.headline)
                .padding()

            if let issue = issue {
                Text("Detail for: \(issue)")
            } else {
                Text("Select an issue from the nav panel")
                    .foregroundColor(.secondary)
            }
        }
    }
}

