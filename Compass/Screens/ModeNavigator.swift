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
            IssuesNavPanel()       // ✅ file exists
        case .pleadings:
            PleadingsNavPanel()    // 🚨 must create this file
        }
    }

    // Right-hand main panel
    @ViewBuilder
    static func mainPanel(for mode: CompassMode) -> some View {
        switch mode {
        case .issues:
            IssuesMainPanel()      // 🚨 must create this file
        case .pleadings:
            PleadingsMainPanel()   // ✅ file exists
        }
    }
}

