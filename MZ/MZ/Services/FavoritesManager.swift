import Foundation
import Combine

class FavoritesManager: ObservableObject {
    @Published var favoriteMovies: [Movie] = []
    private let userDefaults = UserDefaults.standard
    private let favoritesKey = "FavoriteMovies"
    
    init() {
        loadFavorites()
    }
    
    func addToFavorites(_ movie: Movie) {
        if !favoriteMovies.contains(where: { $0.id == movie.id }) {
            favoriteMovies.append(movie)
            saveFavorites()
        }
    }
    
    func removeFromFavorites(_ movie: Movie) {
        favoriteMovies.removeAll { $0.id == movie.id }
        saveFavorites()
    }
    
    func isFavorite(_ movie: Movie) -> Bool {
        return favoriteMovies.contains(where: { $0.id == movie.id })
    }
    
    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favoriteMovies) {
            userDefaults.set(encoded, forKey: favoritesKey)
        }
    }
    
    private func loadFavorites() {
        if let data = userDefaults.data(forKey: favoritesKey),
           let decoded = try? JSONDecoder().decode([Movie].self, from: data) {
            favoriteMovies = decoded
        }
    }
}