import SwiftUI

struct MovieDetailView: View {
    let movie: Movie
    @EnvironmentObject private var tmdbService: TMDBService
    @EnvironmentObject private var favoritesManager: FavoritesManager
    @Environment(\.dismiss) private var dismiss
    @State private var movieDetail: MovieDetail?
    @State private var cast: [Cast] = []
    @State private var crew: [Crew] = []
    @State private var isLoading = true
    @State private var scrollOffset: CGFloat = 0
    @State private var showFullOverview = false
    
    private let headerHeight: CGFloat = 400
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero Section with Parallax Effect
                        heroSection(geometry: geometry)
                        
                        // Content Section
                        contentSection
                    }
                }
                .scrollIndicators(.hidden)
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }
            }
            
            // Navigation Bar
            navigationBar
        }
        .task {
            await loadMovieDetails()
        }
        .preferredColorScheme(.dark)
    }
    
    private func heroSection(geometry: GeometryProxy) -> some View {
        ZStack(alignment: .bottom) {
            // Backdrop Image with Parallax
            AsyncImage(url: URL(string: movie.backdropURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(
                        width: geometry.size.width,
                        height: headerHeight + max(0, scrollOffset)
                    )
                    .offset(y: -scrollOffset * 0.5)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.gray.opacity(0.3), .black],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(height: headerHeight)
            }
            
            // Gradient Overlay
            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(0.3),
                    .black.opacity(0.8),
                    .black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: headerHeight)
            
            // Movie Info Overlay
            movieInfoOverlay
        }
        .frame(height: headerHeight)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: proxy.frame(in: .named("scroll")).minY
                )
            }
        )
    }
    
    private var movieInfoOverlay: some View {
        HStack(alignment: .bottom, spacing: 16) {
            // Poster
            AsyncImage(url: URL(string: movie.posterURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .font(.title)
                    }
            }
            .frame(width: 120, height: 180)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
            .scaleEffect(1 - max(0, scrollOffset) / 1000)
            
            // Movie Info
            VStack(alignment: .leading, spacing: 8) {
                Text(movie.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                if let movieDetail = movieDetail {
                    Text(movieDetail.genres.map(\.name).joined(separator: " • "))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
                
                // Rating and Year
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", movie.voteAverage))
                            .fontWeight(.semibold)
                    }
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(String(movie.releaseDate.prefix(4)))
                    
                    if let runtime = movieDetail?.runtime {
                        Text("•")
                            .foregroundColor(.white.opacity(0.5))
                        Text("\(runtime)m")
                    }
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                // Favorite Button
                favoriteButton
            }
            .frame(height: 180)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private var favoriteButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                if favoritesManager.isFavorite(movie) {
                    favoritesManager.removeFromFavorites(movie)
                } else {
                    favoritesManager.addToFavorites(movie)
                }
            }
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }) {
            HStack(spacing: 8) {
                Image(systemName: favoritesManager.isFavorite(movie) ? "heart.fill" : "heart")
                    .foregroundColor(favoritesManager.isFavorite(movie) ? .red : .white)
                Text(favoritesManager.isFavorite(movie) ? "Favorited" : "Add to Favorites")
                    .fontWeight(.medium)
            }
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            )
        }
        .scaleEffect(favoritesManager.isFavorite(movie) ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: favoritesManager.isFavorite(movie))
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Plot Summary
            if !movie.overview.isEmpty {
                plotSection
            }
            
            // Cast Section
            if !cast.isEmpty {
                castSection
            }
            
            // Crew Section (Directors, Writers)
            if !crew.isEmpty {
                crewSection
            }
            
            // Movie Details
            if let movieDetail = movieDetail {
                movieDetailsSection(movieDetail)
            }
            
            // Bottom padding
            Spacer()
                .frame(height: 100)
        }
        .padding(.top, 24)
        .background(Color.black)
    }
    
    private var plotSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Plot")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(movie.overview)
                .font(.body)
                .foregroundColor(.white.opacity(0.85))
                .lineSpacing(4)
                .lineLimit(showFullOverview ? nil : 4)
                .animation(.easeInOut(duration: 0.3), value: showFullOverview)
            
            if movie.overview.count > 200 {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showFullOverview.toggle()
                    }
                }) {
                    Text(showFullOverview ? "Show Less" : "Show More")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var castSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cast")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(Array(cast.prefix(15).enumerated()), id: \.element.id) { index, member in
                        CastMemberCard(member: member)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.05), value: cast.count)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var crewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Crew")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            let directors = crew.filter { $0.job == "Director" }
            let writers = crew.filter { $0.job == "Writer" || $0.job == "Screenplay" }
            
            VStack(alignment: .leading, spacing: 12) {
                if !directors.isEmpty {
                    CrewRow(title: "Director", members: directors)
                }
                if !writers.isEmpty {
                    CrewRow(title: "Writer", members: writers)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func movieDetailsSection(_ detail: MovieDetail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                if let tagline = detail.tagline, !tagline.isEmpty {
                    DetailRow(title: "Tagline", value: tagline)
                }
                DetailRow(title: "Status", value: detail.status)
                DetailRow(title: "Budget", value: formatCurrency(detail.budget))
                DetailRow(title: "Revenue", value: formatCurrency(detail.revenue))
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var navigationBar: some View {
        VStack {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            Spacer()
        }
    }
    
    private func loadMovieDetails() async {
        do {
            async let detailData = tmdbService.fetchMovieDetails(id: movie.id)
            async let creditsData = tmdbService.fetchMovieCredits(id: movie.id)
            
            let (detail, credits) = try await (detailData, creditsData)
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.movieDetail = detail
                    self.cast = credits.cast
                    self.crew = credits.crew
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
            print("Error loading movie details: \(error)")
        }
    }
    
    private func formatCurrency(_ amount: Int) -> String {
        if amount == 0 { return "N/A" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "N/A"
    }
}

// Supporting Views
struct CastMemberCard: View {
    let member: Cast
    
    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: URL(string: member.profileURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                    Image(systemName: "person.fill")
                        .foregroundColor(.white.opacity(0.5))
                        .font(.title3)
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            
            VStack(spacing: 2) {
                Text(member.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(member.character)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            .frame(width: 80)
        }
    }
}

struct CrewRow: View {
    let title: String
    let members: [Crew]
    
    var body: some View {
        HStack {
            Text(title + ":")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 80, alignment: .leading)
            
            Text(members.map(\.name).joined(separator: ", "))
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title + ":")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }
}

// Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}