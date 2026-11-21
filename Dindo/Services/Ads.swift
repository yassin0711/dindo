import SwiftUI
import GoogleMobileAds

// Tout ce qui concerne les publicités Google est dans ce fichier.
// Le SDK est démarré dans DindoApp (MobileAds.shared.start).

/// Identifiants de TEST fournis par Google : le sujet interdit les vrais identifiants
enum AdUnitID {
    static let banner = "ca-app-pub-3940256099942544/2934735716"
    static let interstitial = "ca-app-pub-3940256099942544/4411468910"
}

/// Bannière : une vue UIKit affichée dans SwiftUI grâce à UIViewRepresentable
struct BannerAdView: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)   // format standard 320 × 50
        banner.adUnitID = AdUnitID.banner
        banner.load(Request())
        return banner
    }

    func updateUIView(_ banner: BannerView, context: Context) {}
}

/// Publicité plein écran (interstitielle) : affichée une fois toutes les 3 saisies enregistrées
@MainActor
final class InterstitialAdService {
    static let shared = InterstitialAdService()

    private var ad: InterstitialAd?
    private var savedCount = 0

    /// Charge une pub à l'avance (au lancement), pour qu'elle s'affiche sans attendre
    func preload() async {
        if ad == nil {
            ad = try? await InterstitialAd.load(with: AdUnitID.interstitial, request: Request())
        }
    }

    /// Appelée après chaque saisie journalière enregistrée
    func recordSaved() async {
        savedCount += 1
        if savedCount % 3 == 0, let ad {
            try? await Task.sleep(for: .milliseconds(600))   // laisser le formulaire se fermer
            ad.present(from: nil)   // nil : le SDK utilise l'écran affiché
            self.ad = nil           // une interstitielle ne s'affiche qu'une seule fois
        }
        await preload()
    }
}
