import Foundation

// Simple user model
struct User: Codable {
    let username: String
    let password: String
}

// Authentication service to manage login state
class AuthenticationService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private let userDefaults = UserDefaults.standard
    private let usersKey = "AppUsers"
    private let currentUserKey = "CurrentUser"
    
    init() {
        loadCurrentUser()
    }
    
    private func loadCurrentUser() {
        // Try to load current user from UserDefaults
        guard let userData = userDefaults.data(forKey: currentUserKey),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            isAuthenticated = false
            currentUser = nil
            return
        }
        
        isAuthenticated = true
        currentUser = user
    }
    
    func register(username: String, password: String) -> Bool {
        // Check if user already exists
        if userExists(username: username) {
            return false
        }
        
        let user = User(username: username, password: password)
        saveUser(user)
        return true
    }
    
    func login(username: String, password: String) -> Bool {
        guard let storedUser = getUser(username: username) else {
            return false
        }
        
        if storedUser.password == password {
            currentUser = storedUser
            isAuthenticated = true
            saveCurrentUser(storedUser)
            return true
        }
        
        return false
    }
    
    func logout() {
        currentUser = nil
        isAuthenticated = false
        userDefaults.removeObject(forKey: currentUserKey)
    }
    
    private func userExists(username: String) -> Bool {
        return getUser(username: username) != nil
    }
    
    private func getUser(username: String) -> User? {
        guard let usersData = userDefaults.data(forKey: usersKey),
              let users = try? JSONDecoder().decode([String:Data].self, from: usersData) else {
            return nil
        }
        
        guard let userData = users[username],
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            return nil
        }
        
        return user
    }
    
    private func saveUser(_ user: User) {
        guard var users = getUsersDictionary() else {
            var users = [String: Data]()
            let userData = try! JSONEncoder().encode(user)
            users[user.username] = userData
            saveUsersDictionary(users)
            return
        }
        
        let userData = try! JSONEncoder().encode(user)
        users[user.username] = userData
        saveUsersDictionary(users)
    }
    
    private func getUsersDictionary() -> [String: Data]? {
        guard let usersData = userDefaults.data(forKey: usersKey) else {
            return nil
        }
        
        return try? JSONDecoder().decode([String: Data].self, from: usersData)
    }
    
    private func saveUsersDictionary(_ users: [String: Data]) {
        let usersData = try! JSONEncoder().encode(users)
        userDefaults.set(usersData, forKey: usersKey)
    }
    
    private func saveCurrentUser(_ user: User) {
        let userData = try! JSONEncoder().encode(user)
        userDefaults.set(userData, forKey: currentUserKey)
    }
}
