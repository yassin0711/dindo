import Foundation

/// Règles des formulaires : chaque fonction renvoie la clé du message d'erreur, ou nil si c'est valide
enum Validation {

    // MARK: Connexion et inscription

    static func name(_ name: String) -> String? {
        name.trimmingCharacters(in: .whitespaces).count >= 2 ? nil : "validation.name"
    }

    /// Forme attendue : texte@domaine.extension (exemple : ali@gmail.com), sans espace
    static func email(_ email: String) -> String? {
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty, !email.contains(" ") else { return "validation.email" }
        let domain = parts[1]
        let isValid = domain.contains(".") && !domain.hasPrefix(".") && !domain.hasSuffix(".")
        return isValid ? nil : "validation.email"
    }

    static func password(_ password: String) -> String? {
        password.count >= 6 ? nil : "validation.password"
    }

    static func confirmation(_ password: String, _ confirmation: String) -> String? {
        password == confirmation ? nil : "validation.confirm"
    }

    // MARK: Formulaires de l'élevage

    static func required(_ text: String) -> String? {
        text.trimmingCharacters(in: .whitespaces).isEmpty ? "validation.required" : nil
    }

    /// Lit un nombre tapé au clavier : accepte « 4.5 » et « 4,5 »
    static func number(_ text: String) -> Double? {
        Double(text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
    }

    /// Nombre de dindonneaux à l'arrivée : entier entre 1 et 100 000,
    /// et pas moins que les dindes déjà mortes ou vendues (modification d'une bande)
    static func flockSize(_ text: String, alreadyUsed: Int) -> String? {
        guard let count = Int(text), count > 0, count <= 100_000 else { return "validation.count" }
        return count >= alreadyUsed ? nil : "validation.count.used"
    }

    /// Morts ou dindes vendues : entier positif, pas plus que les dindes vivantes
    static func birds(_ text: String, alive: Int) -> String? {
        guard let count = Int(text), count >= 0 else { return "validation.integer" }
        return count <= alive ? nil : "validation.birds.tooMany"
    }

    /// Aliment, eau : nombre positif ou nul
    static func quantity(_ text: String) -> String? {
        guard let value = number(text), value >= 0 else { return "validation.number" }
        return nil
    }

    /// Poids moyen : facultatif, entre 0 et 40 kg (un gros mâle pèse environ 20 kg)
    static func weight(_ text: String) -> String? {
        if text.trimmingCharacters(in: .whitespaces).isEmpty { return nil }
        guard let value = number(text), value > 0 else { return "validation.number" }
        return value <= 40 ? nil : "validation.weight"
    }

    /// Montant d'une vente ou d'une dépense : strictement positif
    static func amount(_ text: String) -> String? {
        guard let value = number(text), value > 0 else { return "validation.amount" }
        return nil
    }
}
