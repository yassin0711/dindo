import SwiftUI

/// Tableau de bord : météo de la ferme, chiffres de l'élevage, bandes en cours
struct DashboardView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var flocks: FlockService
    @EnvironmentObject private var weather: WeatherService
    @AppStorage(FarmLocation.latitudeKey) private var latitude = FarmLocation.defaultLatitude
    @AppStorage(FarmLocation.longitudeKey) private var longitude = FarmLocation.defaultLongitude

    // Totaux sur les bandes en cours
    private var alive: Int { flocks.activeFlocks.reduce(0) { $0 + $1.alive } }
    private var deaths: Int { flocks.activeFlocks.reduce(0) { $0 + $1.deaths } }
    private var sold: Int { flocks.flocks.reduce(0) { $0 + $1.sold } }
    private var mortality: Double {
        let initial = flocks.activeFlocks.reduce(0) { $0 + $1.initialCount }
        return initial == 0 ? 0 : Double(deaths) / Double(initial) * 100
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(String(format: "dashboard.hello".localized, auth.user?.displayName ?? ""))
                        .font(.title2.bold())

                    // Bonus hors ligne : Firestore garde les données et enverra les saisies plus tard
                    if flocks.isOffline {
                        Label("dashboard.offline".localized, systemImage: "icloud.slash")
                            .font(.footnote)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    weatherCard

                    LazyVGrid(columns: [GridItem(), GridItem()], spacing: 12) {
                        StatCard(titleKey: "dashboard.activeFlocks", value: "\(flocks.activeFlocks.count)",
                                 icon: "square.grid.2x2.fill", delay: 0)
                        StatCard(titleKey: "dashboard.alive", value: "\(alive)",
                                 icon: "bird.fill", color: .green, delay: 0.1)
                        StatCard(titleKey: "dashboard.mortality", value: mortality.short + " %",
                                 icon: "heart.slash.fill", color: mortality > 5 ? .red : .orange, delay: 0.2)
                        StatCard(titleKey: "dashboard.sold", value: "\(sold)",
                                 icon: "cart.fill", color: .blue, delay: 0.3)
                    }

                    Text("dashboard.activeTitle".localized)
                        .font(.headline)

                    if flocks.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if flocks.activeFlocks.isEmpty {
                        ContentUnavailableView("dashboard.empty.title".localized, systemImage: "bird",
                                               description: Text("dashboard.empty.message".localized))
                    } else {
                        ForEach(flocks.activeFlocks) { flock in
                            NavigationLink {
                                FlockDetailView(flockID: flock.id ?? "")
                            } label: {
                                FlockRow(flock: flock)
                                    .padding()
                                    .background(Color(.secondarySystemBackground),
                                                in: RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                    }
                }
                .padding()
                .animation(.easeInOut, value: flocks.isOffline)
            }
            .safeAreaInset(edge: .bottom) {
                BannerAdView()
                    .frame(width: 320, height: 50)
                    .frame(maxWidth: .infinity)
            }
            .navigationTitle("tab.dashboard".localized)
            .refreshable {
                await weather.load(latitude: latitude, longitude: longitude)
            }
            .task {
                if weather.weather == nil {
                    await weather.load(latitude: latitude, longitude: longitude)
                }
            }
        }
    }

    /// Météo du jour + conseil pour les dindes (l'icône pulse en cas d'alerte)
    @ViewBuilder
    private var weatherCard: some View {
        if let current = weather.weather?.current {
            let alert = Weather.isAlert(current.temperature)
            HStack(spacing: 16) {
                Image(systemName: Weather.icon(for: current.weatherCode))
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 44))
                    .symbolEffect(.pulse, isActive: alert)
                VStack(alignment: .leading, spacing: 4) {
                    Text(current.temperature.short + " °C")
                        .font(.title.bold())
                        .contentTransition(.numericText())
                    Text(Weather.adviceKey(for: current.temperature).localized)
                        .font(.subheadline)
                        .foregroundStyle(alert ? Color.red : Color.secondary)
                    if weather.isFromCache {
                        Text("weather.cached".localized)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(alert ? Color.red.opacity(0.12) : Color.blue.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 16))
        } else if weather.isLoading {
            ProgressView("weather.loading".localized)
                .frame(maxWidth: .infinity)
        } else if let errorKey = weather.errorKey {
            HStack {
                Label(errorKey.localized, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("state.retry".localized) {
                    Task { await weather.load(latitude: latitude, longitude: longitude) }
                }
            }
        }
    }
}

/// Ligne d'une bande : nom, souche, âge et dindes vivantes
struct FlockRow: View {
    let flock: Flock

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: flock.isFinished ? "checkmark.seal.fill" : "bird.fill")
                .font(.title2)
                .foregroundStyle(flock.isFinished ? Color.secondary : Color.accentColor)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(flock.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("\(flock.strain.localized) · \(flock.building)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "flock.day".localized, flock.ageInDays))
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                Text(String(format: "flock.aliveCount".localized, flock.alive))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
