import SwiftUI

/// Ventes et dépenses de la bande, avec le bénéfice estimé
struct FinanceView: View {
    @ObservedObject var data: FlockDataService
    let flock: Flock

    @State private var showForm = false

    var body: some View {
        List {
            Section {
                LabeledContent("money.sales".localized, value: data.totalSales.dinars)
                LabeledContent("money.expenses".localized, value: data.totalExpenses.dinars)
                LabeledContent("money.profit".localized) {
                    Text(data.profit.dinars)
                        .bold()
                        .foregroundStyle(data.profit >= 0 ? Color.green : Color.red)
                        .contentTransition(.numericText())
                }
            }

            Section("money.history".localized) {
                if data.isLoading {
                    ProgressView()
                } else if data.money.isEmpty {
                    ContentUnavailableView("money.empty.title".localized, systemImage: "banknote",
                                           description: Text("money.empty.message".localized))
                } else {
                    ForEach(data.money) { entry in
                        HStack {
                            Image(systemName: entry.kind == .sale ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                .foregroundStyle(entry.kind == .sale ? Color.green : Color.red)
                            VStack(alignment: .leading) {
                                Text(entry.label)
                                Text(entry.date, format: .dateTime.day().month().year())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text((entry.kind == .sale ? "+" : "−") + entry.amount.dinars)
                                if entry.birds > 0 {
                                    Text(String(format: "money.birdsCount".localized, entry.birds))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .swipeActions {
                            Button("common.delete".localized, role: .destructive) {
                                data.deleteMoney(entry)
                            }
                        }
                    }
                }
            }
        }
        .animation(.default, value: data.money)
        .navigationTitle("money.title".localized)
        .toolbar {
            Button {
                showForm = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showForm) {
            MoneyFormView(data: data, flock: flock)
        }
    }
}
