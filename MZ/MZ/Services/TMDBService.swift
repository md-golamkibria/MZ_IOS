import Foundation
import Combine

class TMDBService: ObservableObject {
    private let apiKey = " "
    private let baseURL = "https://api.themoviedb.org/3"
    @Published var genres: [Genre] = []

    func fetchPopularMovies() async throws -> [Movie] {
        let url = URL(string: "\(baseURL)/movie/popular?api_key=\(apiKey)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(MovieResponse.self, from: data)
        return response.results
    }
    
    func fetchMovieDetails(id: Int) async throws -> MovieDetail {
        let url = URL(string: "\(baseURL)/movie/\(id)?api_key=\(apiKey)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(MovieDetail.self, from: data)
    }
    
    func fetchMovieCredits(id: Int) async throws -> CreditsResponse {
        let url = URL(string: "\(baseURL)/movie/\(id)/credits?api_key=\(apiKey)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(CreditsResponse.self, from: data)
    }
    
    func searchMovies(query: String) async throws -> [Movie] {
        guard !query.isEmpty else { return [] }
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let url = URL(string: "\(baseURL)/search/movie?api_key=\(apiKey)&query=\(encodedQuery)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(MovieResponse.self, from: data)
        return response.results
    }
    
    func fetchGenres() async throws -> [Genre] {
        let url = URL(string: "\(baseURL)/genre/movie/list?api_key=\(apiKey)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(GenreResponse.self, from: data)
        return response.genres
    }
    
    func discoverMovies(with genreId: Int? = nil, minRating: Double? = nil, withPerson: String? = nil) async throws -> [Movie] {
        var urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&sort_by=popularity.desc"
        
        if let genreId = genreId {
            urlString += "&with_genres=\(genreId)"
        }
        
        if let minRating = minRating {
            urlString += "&vote_average.gte=\(minRating)"
        }
        
        // If person name is provided, search for person first and get their ID
        if let personName = withPerson, !personName.isEmpty {
            do {
                if let foundPersonId = try await findPersonId(name: personName) {
                    urlString += "&with_people=\(foundPersonId)"
                }
            } catch {
                print("Error finding person: \(error)")
            }
        }
        
        let url = URL(string: urlString)!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(MovieResponse.self, from: data)
        return response.results
    }
    
    func findPersonId(name: String) async throws -> Int? {
        guard !name.isEmpty else { return nil }
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let url = URL(string: "\(baseURL)/search/person?api_key=\(apiKey)&query=\(encodedName)")!
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(PersonSearchResponse.self, from: data)
        
        return response.results.first?.id
    }
    
    func searchPerson(name: String) async throws -> [Movie] {
        guard !name.isEmpty else { return [] }
        
        // First find the person ID
        guard let _ = try await findPersonId(name: name) else {
            return []
        }
        
        // Then discover movies with that person
        return try await discoverMovies(withPerson: name)
    }
}

// Add these new structs for person search
struct PersonSearchResponse: Codable {
    let results: [Person]
}

struct Person: Codable {
    let id: Int
    let name: String
}
