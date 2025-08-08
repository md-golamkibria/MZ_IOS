import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var favoritesManager: FavoritesManager
    @EnvironmentObject private var tmdbService: TMDBService
    @State private var genres: [Genre] = []
    @State private var selectedMovie: Movie?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [.black, .gray.opacity(0.8), .black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("My Favorites")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: "heart.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                        }
                        
                        Text("\(favoritesManager.favoriteMovies.count) favorite movies")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    if favoritesManager.favoriteMovies.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "heart")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.4))
                            
                            Text("No favorite movies yet")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("Double tap on any movie to add it to your favorites")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ], spacing: 20) {
                                ForEach(favoritesManager.favoriteMovies) { movie in
                                    MovieCard(
                                        movie: movie,
                                        genres: genres,
                                        onTap: {
                                            selectedMovie = movie
                                        },
                                        onDoubleTap: {
                                            favoritesManager.removeFromFavorites(movie)
                                        }
                                    )
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            favoritesManager.removeFromFavorites(movie)
                                        } label: {
                                            Label("Remove from Favorites", systemImage: "heart.slash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Bottom padding for dock
                            Spacer()
                                .frame(height: 100)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $selectedMovie) { movie in
            MovieDetailView(movie: movie)
        }
        .task {
            await loadGenres()
        }
    }
    
    private func loadGenres() async {
        do {
            let fetchedGenres = try await tmdbService.fetchGenres()
            await MainActor.run {
                self.genres = fetchedGenres
            }
        } catch {
            print("Error loading genres: \(error)")
        }
    }
}