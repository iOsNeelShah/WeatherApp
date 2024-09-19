//
//  WeatherModel.swift
//  WeatherApp
//

import Foundation
import UIKit

struct Weather: Codable {
    let main: Main
    let weatherDetail: [WeatherDetail]
    
    init(main: Main, weatherDetail: [WeatherDetail]) {
        self.main = main
        self.weatherDetail = weatherDetail
    }
    
    enum CodingKeys: String, CodingKey{
        case main = "main"
        case weatherDetail = "weather"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.main = try container.decode(Main.self, forKey: .main)
        self.weatherDetail = try container.decode([WeatherDetail].self, forKey: .weatherDetail)
    }
}

struct GeoCoding: Codable {
    let name: String
    let country: String
    let state: String
}

struct Main: Codable {
    let temp: Double
    let humidity: Int
}

struct WeatherDetail: Codable {
    let description: String
    let icon: String
}

class ImageCache {
    static let shared = NSCache<NSString, UIImage>()
}
