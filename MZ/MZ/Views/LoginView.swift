import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @State private var username = ""
    @State private var password = ""
    @State private var isSignUpMode = false
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.black, .gray.opacity(0.8), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Logo/Title
                VStack(spacing: 8) {
                    Text("MovieZone")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(isSignUpMode ? "Create Account" : "Sign in to your account")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 32)
                
                // Form
                VStack(spacing: 16) {
                    // Username field
                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .padding(.horizontal)
                        .autocapitalization(.none)
                    
                    // Password field
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    // Confirm Password field (only for signup)
                    if isSignUpMode {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                    }
                }
                
                // Error message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // Action Button
                Button(action: isSignUpMode ? signUp : login) {
                    Text(isSignUpMode ? "Sign Up" : "Sign In")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(isFormInvalid)
                
                // Toggle between login/signup
                Button(action: toggleMode) {
                    Text(isSignUpMode ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .foregroundColor(.blue)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var isFormInvalid: Bool {
        return username.isEmpty || password.isEmpty || (isSignUpMode && confirmPassword.isEmpty)
    }
    
    private func login() {
        if authService.login(username: username, password: password) {
            errorMessage = ""
        } else {
            errorMessage = "Invalid username or password"
        }
    }
    
    private func signUp() {
        // Validate passwords match
        if password != confirmPassword {
            errorMessage = "Passwords do not match"
            return
        }
        
        // Try to register the user
        if authService.register(username: username, password: password) {
            // Auto-login after successful registration
            if authService.login(username: username, password: password) {
                errorMessage = ""
            } else {
                errorMessage = "Registration successful but login failed"
            }
        } else {
            errorMessage = "Username already exists"
        }
    }
    
    private func toggleMode() {
        isSignUpMode.toggle()
        errorMessage = ""
        password = ""
        confirmPassword = ""
    }
}
