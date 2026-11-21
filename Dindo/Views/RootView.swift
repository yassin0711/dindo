import SwiftUI

/// Aiguillage principal : connexion si personne n'est connecté, sinon l'application
struct RootView: View {
    @EnvironmentObject private var auth: AuthService
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .deviceDefault

    var body: some View {
        ZStack {
            if auth.isFirebaseConfigured && auth.user == nil {
                LoginView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    // Changer de langue reconstruit l'interface pour retraduire tous les textes
                    .id(language)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: auth.user?.uid)
    }
}
