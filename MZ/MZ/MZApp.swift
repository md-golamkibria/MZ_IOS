// - //
// - //  MZApp.swift
// - //  MZ
// - //
// - //  Created by apple on 29/07/2025.
// - //
// -
import SwiftUI

@main
struct MZApp: App {
// -   @StateObject private var tmdbService = TMDBService()
// -   @StateObject private var favoritesManager = FavoritesManager()
// -
// -   var body: some Scene {
// -       WindowGroup {
// -           ContentView()
// -               .environmentObject(tmdbService)
// -               .environmentObject(favoritesManager)
// -       }
// -   }
    @StateObject private var authService = AuthenticationService()
    @StateObject private var tmdbService = TMDBService()
    @StateObject private var favoritesManager = FavoritesManager()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    ContentView()
                        .environmentObject(tmdbService)
                        .environmentObject(favoritesManager)
                } else {
                    LoginView()
                }
            }
            .environmentObject(authService)
        }
    }
}
// -

