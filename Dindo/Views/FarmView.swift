import SwiftUI
import MapKit

/// Ma ferme : position sur la carte (bonus Maps) + météo détaillée sur 5 jours
struct FarmView: View {
    @EnvironmentObject private var weather: WeatherService
    @AppStorage(FarmLocation.latitudeKey) private var latitude = FarmLocation.defaultLatitude
    @AppStorage(FarmLocation.longitudeKey) private var longitude = FarmLocation.defaultLongitude
    @State private var camera: MapCameraPosition = .automatic

    private var farm: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    // MapReader : transforme le point touché sur l'écran en coordonnées GPS
                    MapReader { proxy in
                        Map(position: $camera) {
                            Marker("farm.marker".localized, systemImage: "house.fill", coordinate: farm)
                                .tint(.orange)
                        }
                        .onTapGesture { point in
                            if let coordinate = proxy.convert(point, from: .local) {
                                withAnimation {
                                    latitude = coordinate.latitude
                                    longitude = coordinate.longitude
                                }
                                Task { await reload() }   // météo du nouvel endroit
                            }
                        }
                    }
                    .frame(height: 280)
                    .listRowInsets(EdgeInsets())
                } footer: {
                    Text("farm.map.hint".localized)
                }

                weatherSections
            }
            .navigationTitle("tab.farm".localized)
            .refreshable { await reload() }
            .onAppear {
                camera = .region(MKCoordinateRegion(center: farm,
                                                    span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)))
            }
            .task {
                if weather.weather == nil {
                    await reload()
                }
            }
        }
    }

    @ViewBuilder
    private var weatherSections: some View {
        if let current = weather.weather {
            Section("farm.now".localized) {
                LabeledContent("farm.temperature".localized, value: current.current.temperature.short + " °C")
                LabeledContent("farm.humidity".localized, value: current.current.humidity.short + " %")
                LabeledContent("farm.wind".localized, value: current.current.windSpeed.short + " km/h")
                Label(Weather.adviceKey(for: current.current.temperature).localized,
                      systemImage: Weather.isAlert(current.current.temperature) ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundStyle(Weather.isAlert(current.current.temperature) ? Color.red : Color.green)
                if weather.isFromCache {
                    Text("weather.cached".localized)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Section("farm.forecast".localized) {
                ForEach(current.days) { day in
                    HStack {
                        Text(day.date, format: .dateTime.weekday(.wide))
                        Spacer()
                        Image(systemName: Weather.icon(for: day.code))
                            .symbolRenderingMode(.multicolor)
                            .frame(width: 40)
                        Text(day.min.short + "° / " + day.max.short + "°")
                            .monospacedDigit()
                            .foregroundStyle(day.max >= 30 ? Color.red : Color.primary)
                    }
                }
            }
        } else if weather.isLoading {
            Section {
                ProgressView("weather.loading".localized)
                    .frame(maxWidth: .infinity)
            }
        } else if let errorKey = weather.errorKey {
            Section {
                ErrorStateView(messageKey: errorKey) {
                    Task { await reload() }
                }
            }
        }
    }

    private func reload() async {
        await weather.load(latitude: latitude, longitude: longitude)
    }
}
