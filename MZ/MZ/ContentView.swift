//
//  ContentView.swift
//  MZ
//
//  Created by apple on 29/07/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var favoritesManager: FavoritesManager
    @EnvironmentObject private var tmdbService: TMDBService // Add TMDBService
    @State private var selectedTab = 0

    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [.black, .gray.opacity(0.8), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Main content based on selected tab
            Group {
                switch selectedTab {
                case 0:
                    HomeView()
                case 1:
                    ExploreView()
                case 2:
                    SearchView()
                case 3:
                    FavoritesView()
                default:
                    HomeView()
                }
            }
            // No need to pass environment objects manually, they are inherited.
            
            // Modern Dock overlay
            VStack {
                Spacer()
                ModernDock(selectedTab: $selectedTab)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .environmentObject(TMDBService())
        .environmentObject(FavoritesManager())
}