import Foundation

/// Réponse de l'API Open-Meteo (météo actuelle + prévisions sur 5 jours)
struct Weather: Decodable {
    let current: Current
    let daily: Daily

    struct Current: Decodable {
        let temperature: Double
        let humidity: Double
        let windSpeed: Double
        let weatherCode: Int

        // Noms des champs dans le JSON de l'API
        enum CodingKeys: String, CodingKey {
            case temperature = "temperature_2m"
            case humidity = "relative_humidity_2m"
            case windSpeed = "wind_speed_10m"
            case weatherCode = "weather_code"
        }
    }

    struct Daily: Decodable {
        let time: [Double]            // dates en secondes depuis 1970 (timeformat=unixtime)
        let weatherCode: [Int]
        let maxTemperature: [Double]
        let minTemperature: [Double]

        enum CodingKeys: String, CodingKey {
            case time
            case weatherCode = "weather_code"
            case maxTemperature = "temperature_2m_max"
            case minTemperature = "temperature_2m_min"
        }
    }

    /// Une ligne des prévisions
    struct Day: Identifiable {
        let id: Int
        let date: Date
        let code: Int
        let max: Double
        let min: Double
    }

    /// Les prévisions jour par jour (l'API renvoie un tableau par valeur)
    var days: [Day] {
        daily.time.indices.map { i in
            Day(id: i,
                date: Date(timeIntervalSince1970: daily.time[i]),
                code: daily.weatherCode[i],
                max: daily.maxTemperature[i],
                min: daily.minTemperature[i])
        }
    }

    /// Conseil pour l'éleveur selon la température
    /// (la dinde supporte mal la chaleur ; les dindonneaux craignent le froid)
    static func adviceKey(for temperature: Double) -> String {
        if temperature >= 30 { return "weather.advice.hot" }
        if temperature <= 10 { return "weather.advice.cold" }
        return "weather.advice.ok"
    }

    static func isAlert(_ temperature: Double) -> Bool {
        temperature >= 30 || temperature <= 10
    }

    /// Icône SF Symbols selon le code météo de l'API (codes WMO)
    static func icon(for code: Int) -> String {
        switch code {
        case 0: return "sun.max.fill"
        case 1...3: return "cloud.sun.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51...67, 80...82: return "cloud.rain.fill"
        case 71...77, 85, 86: return "cloud.snow.fill"
        case 95...99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }
}
