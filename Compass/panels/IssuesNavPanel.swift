import SwiftUI

struct IssuesNavPanel: View {
    // Temporary stub arguments with defaults
    var issues: [String] = []
    var selectedIssue: String? = nil
    var onDeleteIndex: (Int) -> Void = { _ in }
    var onReorderByID: (String, String) -> Void = { _, _ in }

    var body: some View {
        VStack {
            Text("🗂 IssuesNavPanel (stub)")
                .font(.headline)
                .padding()

            if issues.isEmpty {
                Text("No issues yet")
                    .foregroundColor(.secondary)
            } else {
                List(issues, id: \.self) { issue in
                    Text(issue)
                }
            }
        }
    }
}

