import SwiftUI

struct ExploreView: View {
    @EnvironmentObject private var tmdbService: TMDBService
    @EnvironmentObject private var favoritesManager: FavoritesManager
    @State private var directorActorInput = ""
    @State private var selectedGenre: Genre?
    @State private var ratingInput = ""
    @State private var genres: [Genre] = []
    @State private var filteredMovies: [Movie] = []
    @State private var isLoading = false
    @State private var selectedMovie: Movie?
    @State private var showGenrePicker = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [.black, .gray.opacity(0.8), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Explore Movies")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: "sparkles")
                                .font(.title2)
                                .foregroundColor(.yellow)
                        }
                        
                        Text("Find movies by your preferences")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Filters Card
                    VStack(spacing: 20) {
                        // Director/Actor Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Director/Actor:")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Enter name...", text: $directorActorInput)
                                .textFieldStyle(ModernTextFieldStyle())
                        }
                        
                        // Genre Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Genre:")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Button(action: { 
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showGenrePicker.toggle() 
                                }
                            }) {
                                HStack {
                                    Text(selectedGenre?.name ?? "Select genre...")
                                        .foregroundColor(selectedGenre != nil ? .white : .white.opacity(0.6))
                                    Spacer()
                                    Image(systemName: showGenrePicker ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.white.opacity(0.6))
                                        .rotationEffect(.degrees(showGenrePicker ? 180 : 0))
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                        
                        // Rating Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Minimum Rating:")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Rating (0-10)", text: $ratingInput)
                                .textFieldStyle(ModernTextFieldStyle())
                                .keyboardType(.decimalPad)
                        }
                        
                        // Action Buttons
                        HStack(spacing: 12) {
                            // Clear Filters Button
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    directorActorInput = ""
                                    selectedGenre = nil
                                    ratingInput = ""
                                    filteredMovies = []
                                }
                            }) {
                                HStack {
                                    Image(systemName: "xmark.circle")
                                    Text("Clear")
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial)
                                .cornerRadius(10)
                            }
                            
                            // Suggest Button
                            Button(action: {
                                Task {
                                    await suggestMovies()
                                }
                            }) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "sparkles")
                                        Text("Suggest")
                                    }
                                }
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(10)
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .disabled(isLoading)
                        }
                    }
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    // Results Section
                    if !filteredMovies.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Suggested Movies")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("\(filteredMovies.count) results")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal, 20)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ], spacing: 20) {
                                ForEach(Array(filteredMovies.enumerated()), id: \.element.id) { index, movie in
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
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.05), value: filteredMovies.count)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    } else if !isLoading && hasActiveFilters {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.4))
                            
                            Text("No movies found")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("Try adjusting your filters or search criteria")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    }
                    
                    // Bottom padding for dock
                    Spacer()
                        .frame(height: 100)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showGenrePicker) {
            GenrePickerSheet(genres: genres, selectedGenre: $selectedGenre)
        }
        .sheet(item: $selectedMovie) { movie in
            MovieDetailView(movie: movie)
        }
        .task {
            await loadGenres()
        }
    }
    
    private var hasActiveFilters: Bool {
        !directorActorInput.isEmpty || selectedGenre != nil || !ratingInput.isEmpty
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
    
    private func suggestMovies() async {
        guard hasActiveFilters else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = true
        }
        
        do {
            let minRating = !ratingInput.isEmpty ? Double(ratingInput) : nil
            let personName = !directorActorInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? directorActorInput.trimmingCharacters(in: .whitespacesAndNewlines) : nil
            
            let movies = try await tmdbService.discoverMovies(
                with: selectedGenre?.id,
                minRating: minRating,
                withPerson: personName
            )
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.filteredMovies = movies
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.isLoading = false
                }
            }
            print("Error fetching suggested movies: \(error)")
        }
    }
}

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(.ultraThinMaterial)
            .foregroundColor(.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
    }
}

struct GenrePickerSheet: View {
    let genres: [Genre]
    @Binding var selectedGenre: Genre?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [.black, .gray.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // None option
                        Button(action: {
                            selectedGenre = nil
                            dismiss()
                        }) {
                            HStack {
                                Text("None")
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.body)
                                Spacer()
                                if selectedGenre == nil {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.title3)
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Genre options
                        ForEach(genres) { genre in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedGenre = genre
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    dismiss()
                                }
                            }) {
                                HStack {
                                    Text(genre.name)
                                        .foregroundColor(.white)
                                        .font(.body)
                                    Spacer()
                                    if selectedGenre?.id == genre.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.title3)
                                    }
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .cornerRadius(12)
                    .padding()
                }
            }
            .navigationTitle("Select Genre")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { 
                        dismiss() 
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}