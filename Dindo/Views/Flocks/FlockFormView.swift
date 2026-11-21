import SwiftUI

/// Formulaire « Nouvelle bande » ou « Modifier la bande »
struct FlockFormView: View {
    let flock: Flock?   // nil = nouvelle bande

    @EnvironmentObject private var flocks: FlockService
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var building = ""
    @State private var strain = Flock.strains[0]
    @State private var count = ""
    @State private var arrivalDate = Date()
    @State private var isFinished = false
    @State private var showErrors = false

    // Dindes déjà mortes ou vendues : l'effectif de départ ne peut pas être plus petit
    private var alreadyUsed: Int { (flock?.deaths ?? 0) + (flock?.sold ?? 0) }

    var body: some View {
        NavigationStack {
            Form {
                Section("flock.section.info".localized) {
                    TextField("flock.name".localized, text: $name)
                    ErrorText(key: showErrors ? Validation.required(name) : nil)

                    TextField("flock.building".localized, text: $building)
                    ErrorText(key: showErrors ? Validation.required(building) : nil)

                    Picker("flock.strain".localized, selection: $strain) {
                        ForEach(Flock.strains, id: \.self) { option in
                            Text(option.localized).tag(option)
                        }
                    }
                }

                Section("flock.section.arrival".localized) {
                    DatePicker("flock.arrival".localized, selection: $arrivalDate,
                               in: ...Date(), displayedComponents: .date)

                    TextField("flock.count".localized, text: $count)
                        .keyboardType(.numberPad)
                    ErrorText(key: showErrors ? Validation.flockSize(count, alreadyUsed: alreadyUsed) : nil)
                }

                if flock != nil {
                    Toggle("flock.finished".localized, isOn: $isFinished)
                }
            }
            .animation(.easeInOut, value: showErrors)
            .navigationTitle((flock == nil ? "flock.new" : "flock.edit").localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized) { save() }
                }
            }
            .onAppear(perform: fill)
        }
    }

    /// Modification : on remplit le formulaire avec la bande existante
    private func fill() {
        guard let flock else { return }
        name = flock.name
        building = flock.building
        strain = flock.strain
        count = "\(flock.initialCount)"
        arrivalDate = flock.arrivalDate
        isFinished = flock.isFinished
    }

    private func save() {
        showErrors = true
        guard Validation.required(name) == nil,
              Validation.required(building) == nil,
              Validation.flockSize(count, alreadyUsed: alreadyUsed) == nil,
              let initialCount = Int(count)
        else { return }

        flocks.save(Flock(
            id: flock?.id,
            name: name.trimmingCharacters(in: .whitespaces),
            arrivalDate: arrivalDate,
            initialCount: initialCount,
            strain: strain,
            building: building.trimmingCharacters(in: .whitespaces),
            isFinished: isFinished,
            deaths: flock?.deaths ?? 0,
            sold: flock?.sold ?? 0
        ))
        dismiss()
    }
}
