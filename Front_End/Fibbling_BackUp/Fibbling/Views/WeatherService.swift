import Foundation
import Combine

// MARK: - Weather Data Models

struct WeatherResponse: Codable {
    let weather: [Weather]
    let main: Main
    let sys: Sys
    let dt: Int
    let timezone: Int
    let name: String
}

struct Weather: Codable {
    let id: Int
    let description: String
}

struct Main: Codable {
    let temp: Double
}

struct Sys: Codable {
    let sunrise: Int
    let sunset: Int
}

// MARK: - Weather Service

class WeatherService {
    // Replace with your actual API key and endpoint if needed.
    private let apiKey = "" // Insert your API key here.
    
    func getWeather(for city: String) -> AnyPublisher<WeatherResponse, Error> {
        // Build the URL for the OpenWeatherMap API (or another weather API)
        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(city)&appid=\(apiKey)&units=metric"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: WeatherResponse.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}
