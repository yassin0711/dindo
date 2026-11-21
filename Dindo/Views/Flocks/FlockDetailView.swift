import SwiftUI

/// Fiche d'une bande : chiffres clés et accès à la saisie, l'historique, les vaccins et la caisse
struct FlockDetailView: View {
    let flockID: String

    @EnvironmentObject private var flocks: FlockService
    @StateObject private var data: FlockDataService
    @State private var showRecordForm = false
    @State private var showEditForm = false

    init(flockID: String) {
        self.flockID = flockID
        _data = StateObject(wrappedValue: FlockDataService(flockID: flockID))
    }

    var body: some View {
        // La bande est relue dans FlockService : la fiche se met à jour toute seule
        if let flock = flocks.flock(id: flockID) {
            content(flock)
        } else {
            ContentUnavailableView("flock.missing".localized, systemImage: "bird")
        }
    }

    private func content(_ flock: Flock) -> some View {
        List {
            Section {
                LazyVGrid(columns: [GridItem(), GridItem()], spacing: 12) {
                    StatCard(titleKey: "flock.age", value: String(format: "flock.day".localized, flock.ageInDays),
                             icon: "calendar")
                    StatCard(titleKey: "dashboard.alive", value: "\(flock.alive)",
                             icon: "bird.fill", color: .green, delay: 0.1)
                    StatCard(titleKey: "dashboard.mortality", value: flock.mortalityRate.short + " %",
                             icon: "heart.slash.fill", color: flock.mortalityRate > 5 ? .red : .orange, delay: 0.2)
                    StatCard(titleKey: "flock.weight", value: data.lastWeight.map { $0.short + " kg" } ?? "–",
                             icon: "scalemass.fill", color: .blue, delay: 0.3)
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            Section {
                Button {
                    showRecordForm = true
                } label: {
                    Label("record.add".localized, systemImage: "square.and.pencil")
                        .font(.headline)
                }
                .disabled(flock.isFinished)
            }

            Section("flock.section.follow".localized) {
                NavigationLink {
                    HistoryView(data: data)
                } label: {
                    Label("history.title".localized, systemImage: "chart.xyaxis.line")
                }
                NavigationLink {
                    VaccinesView(data: data, flock: flock)
                } label: {
                    Label("vaccines.title".localized, systemImage: "syringe.fill")
                }
                .badge(data.upcomingVaccines.count)   // nombre de vaccins à faire
                NavigationLink {
                    FinanceView(data: data, flock: flock)
                } label: {
                    Label("money.title".localized, systemImage: "banknote.fill")
                }
            }

            Section("flock.section.info".localized) {
                LabeledContent("flock.strain".localized, value: flock.strain.localized)
                LabeledContent("flock.building".localized, value: flock.building)
                LabeledContent("flock.arrival".localized) {
                    Text(flock.arrivalDate, format: .dateTime.day().month().year())
                }
                LabeledContent("flock.count".localized, value: "\(flock.initialCount)")
                LabeledContent("flock.deaths".localized, value: "\(flock.deaths)")
                LabeledContent("flock.sold".localized, value: "\(flock.sold)")
                LabeledContent("flock.feed".localized, value: data.totalFeedKg.short + " kg")
                // Indice de consommation : kg d'aliment pour faire 1 kg de dinde
                if let weight = data.lastWeight, flock.alive > 0 {
                    LabeledContent("flock.fcr".localized,
                                   value: (data.totalFeedKg / (weight * Double(flock.alive))).short)
                }
            }
        }
        .navigationTitle(flock.name)
        .toolbar {
            Button("common.edit".localized) { showEditForm = true }
        }
        .sheet(isPresented: $showRecordForm) {
            RecordFormView(data: data, flock: flock)
        }
        .sheet(isPresented: $showEditForm) {
            FlockFormView(flock: flock)
        }
        .alert("state.error.title".localized, isPresented: $data.showError) {
        } message: {
            Text("error.firestore".localized)
        }
        .onAppear {
            data.startListening()
        }
    }
}
