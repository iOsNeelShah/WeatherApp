//
//  WeatherViewModel.swift
//  WeatherApp
//

import Foundation

class WeatherViewModel {
    @Published var weather: Weather?
    @Published var errorMsg: String?
    
    private let apiKey = "534cbcd725433e2485685336e141c634"

    func fetchWeather(for city: String) {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(city)&appid=\(apiKey)&units=imperial"
        guard let encodedURLString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                      let url = URL(string: encodedURLString) else { return }
        self.executeRequest(url: url, responseModel: Weather.self) { [weak self] result in
            switch result {
            case .success(let response):
                self?.weather = response
            case .failure(let error):
                self?.errorMsg = "Error fetching weather: \(error.localizedDescription)"
            }
        }
    }
    
    func getCityNameBy(latitude lat: Double, longitude long: Double) {
        let urlString = "http://api.openweathermap.org/geo/1.0/reverse?lat=\(lat)&lon=\(long)&limit=1&appid=\(apiKey)"
        guard let url = URL(string: urlString) else { return }
        self.executeRequest(url: url, responseModel: [GeoCoding].self, completion: { [weak self] result in
            switch result {
            case .success(let response):
                if let cityName = response.first?.name {
                    self?.fetchWeather(for: cityName)
                }
            case .failure(let error):
                self?.errorMsg = "Error fetching weather: \(error.localizedDescription)"
                break
            }
        })
    }
    
    private func executeRequest<T: Decodable>(url: URL, responseModel: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else { return }
            
            do {
                let response = try JSONDecoder().decode(responseModel, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
