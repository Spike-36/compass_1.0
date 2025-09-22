//
//  ContentView.swift
//  Compass
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            // 👇 Choose the starting mode here
            CompassScreen(initialMode: .pleadingsPDF)
                .frame(minWidth: 1200, minHeight: 700)
        }
    }
}

