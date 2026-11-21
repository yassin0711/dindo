import SwiftUI

/// Formulaire « Saisie du jour » : morts, aliment, eau et poids moyen
struct RecordFormView: View {
    @ObservedObject var data: FlockDataService
    let flock: Flock

    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var deaths = "0"
    @State private var feed = ""
    @State private var water = ""
    @State private var weight = ""
    @State private var showErrors = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Pas avant l'arrivée de la bande, pas dans le futur
                    DatePicker("record.date".localized, selection: $date,
                               in: flock.arrivalDate...max(flock.arrivalDate, Date()), displayedComponents: .date)
                }

                Section("record.section.health".localized) {
                    LabeledContent("record.deaths".localized) {
                        TextField("0", text: $deaths)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    ErrorText(key: showErrors ? Validation.birds(deaths, alive: flock.alive) : nil)
                }

                Section("record.section.food".localized) {
                    LabeledContent("record.feed".localized) {
                        TextField("kg", text: $feed)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    ErrorText(key: showErrors ? Validation.quantity(feed) : nil)

                    LabeledContent("record.water".localized) {
                        TextField("L", text: $water)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    ErrorText(key: showErrors ? Validation.quantity(water) : nil)
                }

                Section {
                    LabeledContent("record.weight".localized) {
                        TextField("kg", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    ErrorText(key: showErrors ? Validation.weight(weight) : nil)
                } footer: {
                    Text("record.weight.hint".localized)
                }
            }
            .animation(.easeInOut, value: showErrors)
            .navigationTitle("record.add".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized) { save() }
                }
            }
        }
    }

    private func save() {
        showErrors = true
        guard Validation.birds(deaths, alive: flock.alive) == nil,
              Validation.quantity(feed) == nil,
              Validation.quantity(water) == nil,
              Validation.weight(weight) == nil
        else { return }

        data.addRecord(DailyRecord(
            id: nil,
            date: date,
            deaths: Int(deaths) ?? 0,
            feedKg: Validation.number(feed) ?? 0,
            waterLiters: Validation.number(water) ?? 0,
            averageWeightKg: Validation.number(weight)   // nil si le champ est vide
        ))
        dismiss()
        Task { await InterstitialAdService.shared.recordSaved() }
    }
}
