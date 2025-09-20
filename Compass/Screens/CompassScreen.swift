//
//  CompassScreen.swift
//  Compass
//

import SwiftUI

struct CompassScreen: View {
    @State private var mode: CompassMode = .pleadings   // start on Pleadings by default

    var body: some View {
        VStack(spacing: 0) {
            // Mode switcher (at the top)
            HStack {
                Text("Mode:")
                Picker("Mode", selection: $mode) {
                    ForEach(CompassMode.allCases) { m in
                        Text(m.label).tag(m)
                    }
                }
                .pickerStyle(.menu)

                Spacer()
            }
            .padding()
            Divider()

            // Split view (left nav, right main)
            HStack(spacing: 0) {
                ModeNavigator.navPanel(for: mode)
                    .frame(width: 280)
                    .background(Color(nsColor: .windowBackgroundColor))

                Divider()

                ModeNavigator.mainPanel(for: mode)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Compass")
    }
}

#Preview {
    CompassScreen()
}

