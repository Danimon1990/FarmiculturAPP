import SwiftUI

struct AuthView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Logo and Title
                VStack(spacing: 20) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("FarmiculturAPP")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Manage your farm with ease")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Form
                VStack(spacing: 20) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: performAuth) {
                        HStack {
                            if firebaseService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isSignUp ? "Sign Up" : "Sign In")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(firebaseService.isLoading || email.isEmpty || password.isEmpty)
                    
                    Button(action: { isSignUp.toggle() }) {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .foregroundColor(.green)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding()
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(firebaseService.errorMessage ?? "An error occurred")
            }
            .onChange(of: firebaseService.errorMessage) { errorMessage in
                showingAlert = errorMessage != nil
            }
        }
    }
    
    private func performAuth() {
        Task {
            if isSignUp {
                await firebaseService.signUp(email: email, password: password)
            } else {
                await firebaseService.signIn(email: email, password: password)
            }
        }
    }
}

#Preview {
    AuthView()
} 