import SwiftUI

struct MovieCard: View {
    let movie: Movie
    let genres: [Genre]
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    @State private var isAnimating = false
    @State private var showLoveEffect = false
    @State private var isPressed = false
    @State private var tapCount = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                // Movie Poster
                AsyncImage(url: URL(string: movie.posterURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.gray.opacity(0.3), .gray.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            VStack {
                                Image(systemName: "photo.fill")
                                    .foregroundColor(.gray)
                                    .font(.title2)
                                Text("Loading...")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                }
                .frame(width: 150, height: 225)
                .clipped()
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                
                // Rating Badge
                VStack {
                    HStack {
                        Spacer()
                        ratingBadge
                    }
                    Spacer()
                }
                .padding(8)
                
                // Love Effect Overlay
                if showLoveEffect {
                    LoveEffectView()
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                        .allowsHitTesting(false)
                }
            }
            
            // Movie Info
            VStack(alignment: .leading, spacing: 6) {
                Text(movie.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.white)
                
                Text(movieGenres)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
                
                // Year
                if !movie.releaseDate.isEmpty {
                    Text(String(movie.releaseDate.prefix(4)))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(width: 150, alignment: .leading)
        }
        .scaleEffect(isPressed ? 0.95 : (isAnimating ? 0.98 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimating)
        .onTapGesture {
            handleTap()
        }
        .scaleEffect(showLoveEffect ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showLoveEffect)
    }
    
    private var ratingBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.caption2)
                .foregroundColor(.yellow)
            Text(String(format: "%.1f", movie.voteAverage))
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
    
    private func handleTap() {
        tapCount += 1
        
        // Visual feedback for tap
        withAnimation(.easeInOut(duration: 0.1)) {
            isPressed = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = false
            }
        }
        
        // Determine if single or double tap
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if tapCount == 1 {
                // Single tap - show details
                onTap()
            } else if tapCount >= 2 {
                // Double tap - add to favorites
                handleDoubleTap()
            }
            tapCount = 0
        }
    }
    
    private func handleDoubleTap() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            isAnimating = true
            showLoveEffect = true
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        onDoubleTap()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                isAnimating = false
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.4)) {
                showLoveEffect = false
            }
        }
    }
    
    private var movieGenres: String {
        let movieGenreNames = movie.genreIds.compactMap { genreId in
            genres.first(where: { $0.id == genreId })?.name
        }
        return movieGenreNames.prefix(2).joined(separator: " • ")
    }
}

struct LoveEffectView: View {
    @State private var hearts: [HeartParticle] = []
    
    var body: some View {
        ZStack {
            ForEach(hearts, id: \.id) { heart in
                Text("❤️")
                    .font(.system(size: heart.size))
                    .position(x: heart.x, y: heart.y)
                    .opacity(heart.opacity)
                    .scaleEffect(heart.scale)
                    .rotationEffect(.degrees(heart.rotation))
            }
        }
        .frame(width: 150, height: 225)
        .onAppear {
            createHearts()
        }
    }
    
    private func createHearts() {
        hearts.removeAll()
        
        for i in 0..<12 {
            let heart = HeartParticle(
                id: i,
                x: Double.random(in: 20...130),
                y: Double.random(in: 40...185),
                size: Double.random(in: 14...22),
                opacity: 1.0,
                scale: 0.1,
                rotation: Double.random(in: -30...30)
            )
            hearts.append(heart)
            
            withAnimation(.easeOut(duration: 1.0).delay(Double(i) * 0.08)) {
                hearts[i].scale = Double.random(in: 1.2...1.8)
                hearts[i].y -= Double.random(in: 40...80)
                hearts[i].x += Double.random(in: -20...20)
                hearts[i].opacity = 0.0
                hearts[i].rotation += Double.random(in: -60...60)
            }
        }
    }
}

struct HeartParticle {
    let id: Int
    var x: Double
    var y: Double
    let size: Double
    var opacity: Double
    var scale: Double
    var rotation: Double
}