import SwiftUI
import FirebaseCore
import GoogleSignIn
import GoogleMobileAds

@main
struct DindoApp: App {
    // Services partagés par tous les écrans grâce à .environmentObject
    @StateObject private var auth = AuthService()
    @StateObject private var flocks = FlockService()
    @StateObject private var weather = WeatherService()
    @AppStorage(AppTheme.storageKey) private var theme: AppTheme = .system
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .deviceDefault

    init() {
        // Firebase doit être configuré avant AuthService. Il a besoin du fichier
        // GoogleService-Info.plist (voir README) : sans lui, l'app s'ouvre sans connexion.
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }
        // SDK des publicités Google (identifiant de test dans Info.plist)
        MobileAds.shared.start(completionHandler: nil)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(flocks)
                .environmentObject(weather)
                .preferredColorScheme(theme.colorScheme)
                // Couleur principale de l'app (Assets → AccentColor : brun-orangé de la dinde)
                .tint(Color("AccentColor"))
                .environment(\.locale, language.locale)
                .environment(\.layoutDirection, language.layoutDirection)
                .task {
                    // Pas de demande d'autorisation pendant les captures d'écran automatiques (GitHub Actions)
                    if !UserDefaults.standard.bool(forKey: "screenshots") {
                        await NotificationService.requestPermission()
                    }
                    await InterstitialAdService.shared.preload()
                }
                // Retour dans l'app après la fenêtre de connexion Google
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
