import Foundation
import FirebaseFirestore

/// Une bande : un lot de dindonneaux arrivés le même jour dans un bâtiment.
/// Firestore : users/{uid}/flocks/{idBande}
struct Flock: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String
    var arrivalDate: Date
    var initialCount: Int      // nombre de dindonneaux à l'arrivée
    var strain: String         // souche (B.U.T. 6, Hybrid Converter…)
    var building: String
    var isFinished: Bool
    // Compteurs mis à jour à chaque saisie et à chaque vente (FieldValue.increment)
    var deaths: Int
    var sold: Int

    /// Dindes encore présentes dans le bâtiment
    var alive: Int { max(initialCount - deaths - sold, 0) }

    /// Âge de la bande en jours (J0 = jour d'arrivée)
    var ageInDays: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: arrivalDate),
                                           to: calendar.startOfDay(for: Date())).day ?? 0
        return max(days, 0)
    }

    /// Taux de mortalité en %
    var mortalityRate: Double {
        initialCount == 0 ? 0 : Double(deaths) / Double(initialCount) * 100
    }

    /// Souches proposées dans le formulaire
    static let strains = ["B.U.T. 6", "Hybrid Converter", "Hybrid Grade Maker", "Nicholas Select", "flock.strain.local"]
}
