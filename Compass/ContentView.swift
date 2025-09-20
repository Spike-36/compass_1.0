//
//  ContentView.swift
//  Compass
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            CompassScreen()
                .frame(minWidth: 1200, minHeight: 700)
        }
    }
}

