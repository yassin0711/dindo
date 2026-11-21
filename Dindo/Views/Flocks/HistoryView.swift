import SwiftUI
import Charts

/// Historique des saisies + courbe du poids moyen (Swift Charts)
struct HistoryView: View {
    @ObservedObject var data: FlockDataService

    @State private var chartVisible = false   // la courbe monte depuis zéro à l'ouverture

    /// Pesées dans l'ordre chronologique, pour la courbe
    private var weighings: [DailyRecord] {
        data.records.filter { $0.averageWeightKg != nil }.reversed()
    }

    var body: some View {
        Group {
            if data.isLoading {
                LoadingStateView()
            } else if data.records.isEmpty {
                ContentUnavailableView("history.empty.title".localized, systemImage: "chart.xyaxis.line",
                                       description: Text("history.empty.message".localized))
            } else {
                List {
                    if !weighings.isEmpty {
                        Section("history.chart".localized) {
                            Chart(weighings) { record in
                                LineMark(x: .value("Date", record.date),
                                         y: .value("kg", chartVisible ? record.averageWeightKg ?? 0 : 0))
                                    .interpolationMethod(.catmullRom)
                                PointMark(x: .value("Date", record.date),
                                          y: .value("kg", chartVisible ? record.averageWeightKg ?? 0 : 0))
                            }
                            .chartYAxisLabel("kg")
                            .frame(height: 220)
                            .padding(.vertical)
                        }
                    }

                    Section("history.records".localized) {
                        ForEach(data.records) { record in
                            RecordRow(record: record)
                        }
                        .onDelete { indexSet in
                            indexSet.map { data.records[$0] }.forEach(data.deleteRecord)
                        }
                    }
                }
                .animation(.default, value: data.records)
            }
        }
        .navigationTitle("history.title".localized)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) { chartVisible = true }
        }
    }
}

/// Une saisie : date, morts, aliment, eau, poids
struct RecordRow: View {
    let record: DailyRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(record.date, format: .dateTime.weekday(.wide).day().month())
                .font(.headline)
            HStack(spacing: 14) {
                Label("\(record.deaths)", systemImage: "heart.slash")
                    .foregroundStyle(record.deaths > 0 ? Color.red : Color.secondary)
                Label(record.feedKg.short + " kg", systemImage: "leaf.fill")
                Label(record.waterLiters.short + " L", systemImage: "drop.fill")
                if let weight = record.averageWeightKg {
                    Label(weight.short + " kg", systemImage: "scalemass.fill")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}
