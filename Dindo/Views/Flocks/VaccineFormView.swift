import SwiftUI

/// Formulaire « Nouveau vaccin », avec rappel par notification
struct VaccineFormView: View {
    @ObservedObject var data: FlockDataService
    let flock: Flock

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var date = Date()
    @State private var reminder = true
    @State private var showErrors = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("vaccine.name".localized, text: $name)
                    ErrorText(key: showErrors ? Validation.required(name) : nil)

                    // Vaccins courants chez la dinde : un toucher remplit le champ
                    Menu("vaccine.suggestions".localized) {
                        ForEach(Vaccine.suggestions, id: \.self) { key in
                            Button(key.localized) { name = key.localized }
                        }
                    }
                }

                Section {
                    DatePicker("vaccine.date".localized, selection: $date,
                               in: flock.arrivalDate..., displayedComponents: .date)
                    Toggle("vaccine.reminder".localized, isOn: $reminder)
                } footer: {
                    Text("vaccine.reminder.hint".localized)
                }
            }
            .animation(.easeInOut, value: showErrors)
            .navigationTitle("vaccines.add".localized)
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
        guard Validation.required(name) == nil else { return }

        let isPast = date < Calendar.current.startOfDay(for: Date())
        data.addVaccine(Vaccine(id: nil, name: name.trimmingCharacters(in: .whitespaces),
                                date: date, isDone: isPast),   // date passée = déjà fait
                        reminder: reminder, flockName: flock.name)
        dismiss()
    }
}
