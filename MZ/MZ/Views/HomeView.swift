
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var tmdbService: TMDBService
    @EnvironmentObject private var favoritesManager: FavoritesManager
    @EnvironmentObject private var authService: AuthenticationService
    @State private var movies: [Movie] = []
    @State private var genres: [Genre] = []
    @State private var isLoading = true
    @State private var selectedMovie: Movie?
    @State private var showProfileView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [.black, .gray.opacity(0.8), .black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Content
                        contentSection
                        
                        // Bottom padding for dock
                        Spacer()
                            .frame(height: 100)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadData()
        }
        .sheet(item: $selectedMovie) { movie in
            MovieDetailView(movie: movie)
        }
        .sheet(isPresented: $showProfileView) {
            ProfileView()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MovieZone")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Discover the latest movies")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Profile Button
                profileButton
            }
            
            // Stats Row
            statsRow
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var profileButton: some View {
// -         Button(action: {}) {
        Button(action: {
            showProfileView = true
        }) {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                }
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        }
    }
    
    private var statsRow: some View {
        HStack(spacing: 20) {
            StatItem(icon: "film", value: "\(movies.count)", label: "Movies")
            StatItem(icon: "heart.fill", value: "\(favoritesManager.favoriteMovies.count)", label: "Favorites")
            StatItem(icon: "star.fill", value: "8.5", label: "Avg Rating")
        }
        .padding(.top, 8)
    }
    
    private var contentSection: some View {
        Group {
            if isLoading {
                loadingSection
            } else {
                moviesGrid
            }
        }
    }
    
    private var loadingSection: some View {
        VStack(spacing: 20) {
            LoadingDotsView()
            
            Text("Loading movies...")
                .foregroundColor(.white.opacity(0.7))
                .font(.subheadline)
        }
        .frame(height: 200)
    }
    
    private var moviesGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 20) {
            ForEach(movies) { movie in
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
    }
    
    private func loadData() async {
        do {
            async let moviesData = tmdbService.fetchPopularMovies()
            async let genresData = tmdbService.fetchGenres()
            
            let (fetchedMovies, fetchedGenres) = try await (moviesData, genresData)
            
            await MainActor.run {
                self.movies = fetchedMovies
                self.genres = fetchedGenres
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
            print("Error loading data: \(error)")
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.black, .gray.opacity(0.8), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Header
                Text("Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // User Info
                VStack(spacing: 20) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.white)
                    
                    Text(authService.currentUser?.username ?? "Guest")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                // Logout Button
                Button(action: {
                    authService.logout()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Log Out")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding(.top, 50)
        }
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.yellow)
                Text(value)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

struct LoadingDotsView: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(.white.opacity(0.7))
                    .frame(width: 8, height: 8)
                    .scaleEffect(animating ? 1.2 : 0.8)
                    .opacity(animating ? 0.4 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }
}

