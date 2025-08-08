import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var tmdbService: TMDBService
    @EnvironmentObject private var favoritesManager: FavoritesManager
    @State private var searchText = ""
    @State private var searchResults: [Movie] = []
    @State private var genres: [Genre] = []
    @State private var isLoading = false
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
                    // Header with Search Bar
                    VStack(spacing: 16) {
                        Text("Search Movies")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white.opacity(0.6))
                            
                            TextField("Search for movies...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .foregroundColor(.white)
                                .onSubmit {
                                    Task {
                                        await performSearch()
                                    }
                                }
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                    searchResults = []
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Results
                    if isLoading {
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            Text("Searching...")
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.top)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if searchResults.isEmpty && !searchText.isEmpty {
                        VStack {
                            Image(systemName: "magnifyingglass")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.4))
                            Text("No results found")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if !searchResults.isEmpty {
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ], spacing: 20) {
                                ForEach(searchResults) { movie in
                                    MovieCard(
                                        movie: movie,
                                        genres: genres,
                                        onTap: {
                                            selectedMovie = movie
                                        },
                                        onDoubleTap: {
                                            favoritesManager.addToFavorites(movie)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Bottom padding for dock
                            Spacer()
                                .frame(height: 100)
                        }
                    } else {
                        VStack {
                            Image(systemName: "tv")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.4))
                            Text("Search for your favorite movies")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onChange(of: searchText) {
            if searchText.isEmpty {
                searchResults = []
            }
        }
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
    
    private func performSearch() async {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isLoading = true
        
        do {
            let results = try await tmdbService.searchMovies(query: searchText)
            await MainActor.run {
                self.searchResults = results
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
            print("Error searching movies: \(error)")
        }
    }
}