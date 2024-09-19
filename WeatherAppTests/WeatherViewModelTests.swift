//
//  WeatherViewModelTests.swift
//  WeatherApp
//
//

import XCTest
@testable import WeatherApp

final class WeatherViewModelTests: XCTestCase {

    var viewModel: WeatherViewModel!

    override func setUp() {
        super.setUp()
        viewModel = WeatherViewModel()
    }

    func testFetchWeatherSuccess() {
        let expectation = XCTestExpectation(description: "Weather fetch")
        
        viewModel.weather = Weather(main: Main(temp: 75, humidity: 40), weatherDetail: [WeatherDetail(description: "light rain", icon: "10d")])
        
        viewModel.fetchWeather(for: "New York")
        XCTAssertNotNil(self.viewModel.weather)
        XCTAssertNil(self.viewModel.errorMsg)
        expectation.fulfill()
    }
}
