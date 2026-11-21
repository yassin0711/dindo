import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var auth: AuthService

    @State private var email = ""
    @State private var password = ""
    @State private var showErrors = false   // les erreurs s'affichent après le premier essai
    @State private var isLoading = false
    @State private var errorKey: String?    // erreur renvoyée par Firebase
    @State private var appeared = false     // animation du logo

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Logo qui arrive en rebondissant
                    Image(systemName: "bird.circle.fill")
                        .font(.system(size: 90))
                        .foregroundStyle(.tint)
                        .scaleEffect(appeared ? 1 : 0.3)
                        .rotationEffect(.degrees(appeared ? 0 : -30))
                        .opacity(appeared ? 1 : 0)

                    Text("app.name".localized)
                        .font(.largeTitle.bold())
                    Text("app.tagline".localized)
                        .foregroundStyle(.secondary)

                    FormField(titleKey: "auth.email", text: $email,
                              errorKey: showErrors ? Validation.email(email) : nil)

                    FormField(titleKey: "auth.password", text: $password, isSecure: true,
                              errorKey: showErrors ? Validation.password(password) : nil)

                    NavigationLink("auth.forgot.link".localized) { ForgotPasswordView() }
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    if let errorKey {
                        Text(errorKey.localized)
                            .foregroundStyle(.red)
                            .transition(.opacity)
                    }

                    Button {
                        Task { await signIn() }
                    } label: {
                        Text("auth.login.button".localized)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button {
                        Task { await signInWithGoogle() }
                    } label: {
                        Label("auth.google".localized, systemImage: "g.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    if isLoading {
                        ProgressView()
                    }

                    NavigationLink("auth.signup.link".localized) { SignUpView() }
                }
                .padding()
                .disabled(isLoading)
                .animation(.easeInOut, value: showErrors)
                .animation(.easeInOut, value: errorKey)
            }
            .onAppear {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) { appeared = true }
            }
        }
    }

    private func signIn() async {
        showErrors = true
        errorKey = nil
        guard Validation.email(email) == nil, Validation.password(password) == nil else { return }

        isLoading = true
        do {
            try await auth.signIn(email: email, password: password)
        } catch {
            errorKey = AuthService.messageKey(for: error)
        }
        isLoading = false
    }

    private func signInWithGoogle() async {
        errorKey = nil
        isLoading = true
        do {
            try await auth.signInWithGoogle()
        } catch {
            errorKey = AuthService.messageKey(for: error)
        }
        isLoading = false
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthService())
}
