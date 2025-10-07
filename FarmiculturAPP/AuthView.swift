import SwiftUI

struct AuthView: View {
    @EnvironmentObject var farmDataService: FarmDataService
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isSignUp = false
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Logo and Title
                VStack(spacing: 20) {
                    Image("FarmicultureAPP Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                    
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
                    
                    if isSignUp {
                        TextField("Your Name", text: $displayName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    Button(action: performAuth) {
                        HStack {
                            if farmDataService.isLoading {
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
                    .disabled(farmDataService.isLoading || email.isEmpty || password.isEmpty || (isSignUp && displayName.isEmpty))
                    
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
                Text(farmDataService.errorMessage ?? "An error occurred")
            }
            .onChange(of: farmDataService.errorMessage) { errorMessage in
                showingAlert = errorMessage != nil
            }
        }
    }
    
    private func performAuth() {
        Task {
            if isSignUp {
                await farmDataService.signUp(email: email, password: password, displayName: displayName)
            } else {
                await farmDataService.signIn(email: email, password: password)
            }
        }
    }
}

#Preview {
    AuthView()
} 