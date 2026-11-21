import Foundation
import FirebaseFirestore

// Les données enregistrées à l'intérieur d'une bande :
// users/{uid}/flocks/{idBande}/records, /vaccines et /money

/// Saisie journalière
struct DailyRecord: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var date: Date
    var deaths: Int
    var feedKg: Double
    var waterLiters: Double
    var averageWeightKg: Double?   // nil : pas de pesée ce jour-là
}

/// Vaccin prévu ou déjà fait
struct Vaccine: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String
    var date: Date
    var isDone: Bool

    /// Vaccins courants chez la dinde, proposés dans le formulaire
    static let suggestions = ["vaccine.newcastle", "vaccine.he", "vaccine.cholera", "vaccine.pox"]
}

/// Vente ou dépense
struct MoneyEntry: Identifiable, Codable, Hashable {
    enum Kind: String, Codable, CaseIterable {
        case sale, expense
        var titleKey: String { "money.kind.\(rawValue)" }
    }

    @DocumentID var id: String?
    var kind: Kind
    var label: String
    var amount: Double   // en dinars
    var birds: Int       // dindes vendues (0 pour une dépense)
    var date: Date
}
