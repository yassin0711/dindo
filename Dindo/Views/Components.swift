import SwiftUI

// Petites vues réutilisées par plusieurs écrans.
// Pour les états vides, on utilise directement ContentUnavailableView (vue native d'iOS 17).

/// Indicateur de chargement natif + petite dinde animée
struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bird.fill")
                .font(.system(size: 44))
                .foregroundStyle(.tint)
                .symbolEffect(.pulse)
            ProgressView("state.loading".localized)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Message d'erreur clair + bouton « Réessayer »
struct ErrorStateView: View {
    let messageKey: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("state.error.title".localized, systemImage: "wifi.exclamationmark")
        } description: {
            Text(messageKey.localized)
        } actions: {
            Button("state.retry".localized, action: retry)
                .buttonStyle(.borderedProminent)
        }
    }
}

/// Champ des écrans de connexion, avec son message d'erreur en dessous (bordure rouge si erreur)
struct FormField: View {
    let titleKey: String
    @Binding var text: String
    var isSecure = false
    var errorKey: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Group {
                if isSecure {
                    SecureField(titleKey.localized, text: $text)
                } else {
                    TextField(titleKey.localized, text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(errorKey == nil ? Color.clear : Color.red)
            )

            ErrorText(key: errorKey)
        }
    }
}

/// Message d'erreur sous un champ, qui apparaît en glissant
struct ErrorText: View {
    let key: String?

    var body: some View {
        if let key {
            Text(key.localized)
                .font(.caption)
                .foregroundStyle(.red)
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
}

/// Carte de chiffre du tableau de bord : elle apparaît en grandissant, l'une après l'autre
struct StatCard: View {
    let titleKey: String
    let value: String
    let icon: String
    var color: Color = .accentColor
    var delay: Double = 0

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title.bold())
                .contentTransition(.numericText())   // les chiffres défilent quand ils changent
            Text(titleKey.localized)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .scaleEffect(appeared ? 1 : 0.8)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: appeared)
        .animation(.default, value: value)
        .onAppear { appeared = true }
    }
}

/// Animation au toucher : la carte rétrécit légèrement puis rebondit
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(), value: configuration.isPressed)
    }
}

extension Double {
    /// 1250.5 → « 1 250,5 DT »
    var dinars: String {
        formatted(.number.precision(.fractionLength(0...3))) + " " + "currency".localized
    }

    /// 4.25 → « 4,25 »
    var short: String {
        formatted(.number.precision(.fractionLength(0...2)))
    }
}

/// Position de la ferme (choisie sur la carte), gardée sur le téléphone
enum FarmLocation {
    static let latitudeKey = "farm.latitude"
    static let longitudeKey = "farm.longitude"
    // Par défaut : Tunis
    static let defaultLatitude = 36.8065
    static let defaultLongitude = 10.1815
}

#Preview("Carte") {
    StatCard(titleKey: "dashboard.alive", value: "1 240", icon: "bird.fill")
        .padding()
}
