import SwiftUI

struct IssuesMainPanel: View {
    @State private var mode: SentenceListPanel.Mode = .linked   // default to linked
    var selectedIssue: DBIssue? = nil  // plain optional, no binding yet

    var body: some View {
        VStack(spacing: 0) {
            Picker("Mode", selection: $mode) {
                Text("All Sentences").tag(SentenceListPanel.Mode.all)
                Text("Linked Only").tag(SentenceListPanel.Mode.linked)
            }
            .pickerStyle(.segmented)
            .padding()

            Divider()

            SentenceListPanel(mode: mode, selectedIssue: selectedIssue)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Issues")
    }
}

#Preview {
    NavigationView {
        IssuesMainPanel()
    }
}

