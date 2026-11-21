import SwiftUI

/// Programme de vaccination de la bande (à faire / faits)
struct VaccinesView: View {
    @ObservedObject var data: FlockDataService
    let flock: Flock

    @State private var showForm = false

    var body: some View {
        Group {
            if data.isLoading {
                LoadingStateView()
            } else if data.vaccines.isEmpty {
                ContentUnavailableView {
                    Label("vaccines.empty.title".localized, systemImage: "syringe")
                } description: {
                    Text("vaccines.empty.message".localized)
                } actions: {
                    Button("vaccines.add".localized) { showForm = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    section("vaccines.upcoming", data.vaccines.filter { !$0.isDone })
                    section("vaccines.done", data.vaccines.filter { $0.isDone })
                }
                .animation(.default, value: data.vaccines)
            }
        }
        .navigationTitle("vaccines.title".localized)
        .toolbar {
            Button {
                showForm = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showForm) {
            VaccineFormView(data: data, flock: flock)
        }
    }

    @ViewBuilder
    private func section(_ titleKey: String, _ vaccines: [Vaccine]) -> some View {
        if !vaccines.isEmpty {
            Section(titleKey.localized) {
                ForEach(vaccines) { vaccine in
                    HStack {
                        // Toucher le rond coche le vaccin (petit rebond)
                        Button {
                            withAnimation { data.toggleDone(vaccine) }
                        } label: {
                            Image(systemName: vaccine.isDone ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundStyle(vaccine.isDone ? Color.green : Color.secondary)
                                .symbolEffect(.bounce, value: vaccine.isDone)
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading) {
                            Text(vaccine.name.localized)
                                .strikethrough(vaccine.isDone)
                            Text(vaccine.date, format: .dateTime.day().month().year())
                                .font(.caption)
                                .foregroundStyle(isLate(vaccine) ? Color.red : Color.secondary)
                        }
                    }
                    .swipeActions {
                        Button("common.delete".localized, role: .destructive) {
                            data.deleteVaccine(vaccine)
                        }
                    }
                }
            }
        }
    }

    /// Vaccin pas fait alors que la date est passée
    private func isLate(_ vaccine: Vaccine) -> Bool {
        !vaccine.isDone && vaccine.date < Calendar.current.startOfDay(for: Date())
    }
}
