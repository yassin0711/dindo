import FirebaseFirestore

/// Ce que contient une bande : saisies journalières, vaccins, ventes et dépenses.
/// Créé par FlockDetailView (@StateObject) puis passé aux écrans suivants.
final class FlockDataService: ObservableObject {
    @Published private(set) var records: [DailyRecord] = []   // du plus récent au plus ancien
    @Published private(set) var vaccines: [Vaccine] = []
    @Published private(set) var money: [MoneyEntry] = []
    @Published private(set) var isLoading = true
    @Published var showError = false

    let flockID: String
    private var listeners: [ListenerRegistration] = []

    /// users/{uid}/flocks/{flockID}
    private var flockDocument: DocumentReference? {
        userCollection("flocks")?.document(flockID)
    }

    init(flockID: String) {
        self.flockID = flockID
    }

    deinit {
        listeners.forEach { $0.remove() }
    }

    // MARK: Chiffres calculés

    var totalFeedKg: Double { records.reduce(0) { $0 + $1.feedKg } }
    var totalSales: Double { money.filter { $0.kind == .sale }.reduce(0) { $0 + $1.amount } }
    var totalExpenses: Double { money.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount } }
    var profit: Double { totalSales - totalExpenses }

    /// Dernier poids moyen mesuré
    var lastWeight: Double? { records.first { $0.averageWeightKg != nil }?.averageWeightKg }

    /// Vaccins pas encore faits
    var upcomingVaccines: [Vaccine] { vaccines.filter { !$0.isDone } }

    // MARK: Écoute en temps réel

    func startListening() {
        guard listeners.isEmpty else { return }
        // [weak self] : sinon le service ne serait jamais libéré (et les écoutes jamais arrêtées)
        listeners = [
            listen("records") { [weak self] (list: [DailyRecord]) in self?.records = list },
            listen("vaccines") { [weak self] (list: [Vaccine]) in self?.vaccines = list.sorted { $0.date < $1.date } },
            listen("money") { [weak self] (list: [MoneyEntry]) in self?.money = list },
        ].compactMap { $0 }
        if listeners.isEmpty {
            isLoading = false
        }
    }

    /// Écoute une sous-collection de la bande, triée par date (la même chose pour les trois listes)
    private func listen<T: Decodable>(_ name: String, update: @escaping ([T]) -> Void) -> ListenerRegistration? {
        flockDocument?.collection(name)
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                self?.isLoading = false
                if error != nil {
                    self?.showError = true
                }
                update(snapshot?.documents.compactMap { try? $0.data(as: T.self) } ?? [])
            }
    }

    // MARK: Saisies journalières

    func addRecord(_ record: DailyRecord) {
        add(record, to: "records")
        updateCounters(deaths: record.deaths)
    }

    func deleteRecord(_ record: DailyRecord) {
        delete(record.id, from: "records")
        updateCounters(deaths: -record.deaths)
    }

    // MARK: Vaccins

    func addVaccine(_ vaccine: Vaccine, reminder: Bool, flockName: String) {
        guard let id = add(vaccine, to: "vaccines"), reminder else { return }
        NotificationService.scheduleVaccine(id: id, name: vaccine.name.localized,
                                            flockName: flockName, date: vaccine.date)
    }

    func toggleDone(_ vaccine: Vaccine) {
        guard let id = vaccine.id else { return }
        flockDocument?.collection("vaccines").document(id)
            .updateData(["isDone": !vaccine.isDone], completion: handleError)
        if !vaccine.isDone {
            NotificationService.cancel(id: id)   // vaccin fait : plus besoin de rappel
        }
    }

    func deleteVaccine(_ vaccine: Vaccine) {
        if let id = vaccine.id {
            NotificationService.cancel(id: id)
        }
        delete(vaccine.id, from: "vaccines")
    }

    // MARK: Ventes et dépenses

    func addMoney(_ entry: MoneyEntry) {
        add(entry, to: "money")
        updateCounters(sold: entry.birds)
    }

    func deleteMoney(_ entry: MoneyEntry) {
        delete(entry.id, from: "money")
        updateCounters(sold: -entry.birds)
    }

    // MARK: Outils communs

    /// Ajoute un document et renvoie son identifiant
    @discardableResult
    private func add<T: Encodable>(_ item: T, to name: String) -> String? {
        do {
            return try flockDocument?.collection(name).addDocument(from: item, completion: handleError).documentID
        } catch {
            showError = true
            return nil
        }
    }

    private func delete(_ id: String?, from name: String) {
        guard let id else { return }
        flockDocument?.collection(name).document(id).delete(completion: handleError)
    }

    /// Met à jour les compteurs de la bande (morts, vendues) sans relire toutes les saisies
    private func updateCounters(deaths: Int = 0, sold: Int = 0) {
        guard deaths != 0 || sold != 0 else { return }
        flockDocument?.updateData([
            "deaths": FieldValue.increment(Int64(deaths)),
            "sold": FieldValue.increment(Int64(sold)),
        ], completion: handleError)
    }

    private func handleError(_ error: Error?) {
        if error != nil {
            showError = true
        }
    }
}
