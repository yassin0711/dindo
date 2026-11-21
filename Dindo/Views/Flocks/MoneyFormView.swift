import SwiftUI

/// Formulaire « Nouvelle vente / dépense »
struct MoneyFormView: View {
    @ObservedObject var data: FlockDataService
    let flock: Flock

    @Environment(\.dismiss) private var dismiss

    @State private var kind = MoneyEntry.Kind.sale
    @State private var label = ""
    @State private var amount = ""
    @State private var birds = ""
    @State private var date = Date()
    @State private var showErrors = false

    // Champ « dindes vendues » facultatif : vide = 0 (vente de fumier, par exemple)
    private var birdsError: String? {
        birds.isEmpty ? nil : Validation.birds(birds, alive: flock.alive)
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("money.kind".localized, selection: $kind.animation()) {
                    ForEach(MoneyEntry.Kind.allCases, id: \.self) { option in
                        Text(option.titleKey.localized).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                Section {
                    TextField((kind == .sale ? "money.label.sale" : "money.label.expense").localized, text: $label)
                    ErrorText(key: showErrors ? Validation.required(label) : nil)

                    LabeledContent("money.amount".localized) {
                        TextField("currency".localized, text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    ErrorText(key: showErrors ? Validation.amount(amount) : nil)

                    // Le nombre de dindes vendues n'apparaît que pour une vente
                    if kind == .sale {
                        LabeledContent("money.birds".localized) {
                            TextField("0", text: $birds)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }
                        .transition(.opacity)
                        ErrorText(key: showErrors ? birdsError : nil)
                    }

                    DatePicker("money.date".localized, selection: $date, in: ...Date(), displayedComponents: .date)
                }
            }
            .animation(.easeInOut, value: showErrors)
            .navigationTitle("money.add".localized)
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
        guard Validation.required(label) == nil,
              Validation.amount(amount) == nil,
              kind == .expense || birdsError == nil,
              let value = Validation.number(amount)
        else { return }

        data.addMoney(MoneyEntry(
            id: nil,
            kind: kind,
            label: label.trimmingCharacters(in: .whitespaces),
            amount: value,
            birds: kind == .sale ? Int(birds) ?? 0 : 0,
            date: date
        ))
        dismiss()
    }
}
