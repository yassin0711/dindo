import Foundation

/// Météo de la ferme avec l'API REST Open-Meteo (gratuite, sans clé)
@MainActor
final class WeatherService: ObservableObject {
    @Published private(set) var weather: Weather?
    @Published private(set) var isLoading = false
    @Published private(set) var errorKey: String?
    @Published private(set) var isFromCache = false   // vrai = dernière météo enregistrée (hors ligne)

    private let cacheKey = "weather.cache"

    func load(latitude: Double, longitude: Double) async {
        isLoading = true
        errorKey = nil

        let address = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)"
            + "&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min"
            + "&timezone=auto&timeformat=unixtime&forecast_days=5"

        do {
            guard let url = URL(string: address) else { throw URLError(.badURL) }
            // 15 secondes maximum : sinon le chargement pourrait tourner sans fin
            let request = URLRequest(url: url, timeoutInterval: 15)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
            weather = try JSONDecoder().decode(Weather.self, from: data)
            isFromCache = false
            // Bonus hors ligne : on garde la réponse pour la prochaine fois sans réseau
            UserDefaults.standard.set(data, forKey: cacheKey)
        } catch {
            if let data = UserDefaults.standard.data(forKey: cacheKey),
               let cached = try? JSONDecoder().decode(Weather.self, from: data) {
                weather = cached
                isFromCache = true
            } else {
                errorKey = (error as? URLError)?.code == .notConnectedToInternet ? "error.offline" : "error.weather"
            }
        }
        isLoading = false
    }
}
