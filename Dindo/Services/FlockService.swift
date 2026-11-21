import FirebaseFirestore

/// Les bandes de l'éleveur dans Firestore : users/{uid}/flocks/{idBande}
/// Partagé avec toutes les vues grâce à @EnvironmentObject.
final class FlockService: ObservableObject {
    @Published private(set) var flocks: [Flock] = []
    @Published private(set) var isLoading = true   // vrai tant que Firestore n'a pas répondu
    @Published private(set) var isOffline = false  // vrai = données venant du cache du téléphone
    @Published var showError = false               // vrai → MainTabView affiche une alerte

    private var listener: ListenerRegistration?

    var activeFlocks: [Flock] { flocks.filter { !$0.isFinished } }

    func flock(id: String) -> Flock? {
        flocks.first { $0.id == id }
    }

    // MARK: Écoute en temps réel

    func startListening() {
        listener?.remove()
        isLoading = true
        // includeMetadataChanges : on est aussi prévenu quand le réseau revient (bonus hors ligne)
        listener = userCollection("flocks")?
            .order(by: "arrivalDate", descending: true)
            .addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
                self?.isLoading = false
                if error != nil {
                    self?.showError = true
                }
                self?.isOffline = snapshot?.metadata.isFromCache ?? false
                self?.flocks = snapshot?.documents.compactMap { try? $0.data(as: Flock.self) } ?? []
            }
        // Personne n'est connecté : il n'y a rien à attendre
        if listener == nil {
            isLoading = false
        }
    }

    /// Arrête l'écoute (appelée à la déconnexion)
    func stopListening() {
        listener?.remove()
        listener = nil
        flocks = []
    }

    // MARK: Ajouter, modifier, supprimer

    /// Ajoute une nouvelle bande (id == nil) ou enregistre les modifications
    func save(_ flock: Flock) {
        guard let collection = userCollection("flocks") else { return }
        do {
            if let id = flock.id {
                try collection.document(id).setData(from: flock, completion: handleError)
            } else {
                _ = try collection.addDocument(from: flock, completion: handleError)
            }
        } catch {
            showError = true
        }
    }

    /// Supprime la bande et tout ce qu'elle contient (Firestore ne le fait pas tout seul)
    func delete(_ flock: Flock) {
        guard let id = flock.id, let document = userCollection("flocks")?.document(id) else { return }
        for name in ["records", "vaccines", "money"] {
            document.collection(name).getDocuments { snapshot, _ in
                for item in snapshot?.documents ?? [] {
                    NotificationService.cancel(id: item.documentID)   // rappel de vaccin éventuel
                    item.reference.delete()
                }
            }
        }
        document.delete(completion: handleError)
    }

    /// Appelée par Firestore à la fin d'une écriture : error vaut nil si tout s'est bien passé
    private func handleError(_ error: Error?) {
        if error != nil {
            showError = true
        }
    }
}
