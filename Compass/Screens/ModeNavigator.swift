//
//  ModeNavigator.swift
//  Compass
//
//  Created by Pete on 20/09/2025.
//

import SwiftUI

struct ModeNavigator {
    // Left-hand nav panel
    @ViewBuilder
    static func navPanel(for mode: CompassMode) -> some View {
        switch mode {
        case .issues:
            IssuesNavPanel()
        case .pleadings:
            PleadingsNavPanel()
        case .pleadingsPDF:
            PleadingsPDFNavPanel(
                docID: "brown.record"   // default doc for now
            ) { type, number in
                // placeholder action until hooked to PDF scrolling
                print("Selected \(type) \(number)")
            }
        case .splitSentences:
            SplitSentencesNavPanel()
        case .sideBySide:
            SideBySideNavPanel()
        }
    }

    // Right-hand main panel
    @ViewBuilder
    static func mainPanel(for mode: CompassMode) -> some View {
        switch mode {
        case .issues:
            IssuesMainPanel()
        case .pleadings:
            PleadingsMainPanel()
        case .pleadingsPDF:
            PleadingsPDFMainPanel()
        case .splitSentences:
            SplitSentencesMainPanel()
        case .sideBySide:
            SideBySideMainPanel()
        }
    }
}

