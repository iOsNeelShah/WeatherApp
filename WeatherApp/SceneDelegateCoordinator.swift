//
//  AppCoordinator.swift
//  WeatherApp
//

import UIKit

class SceneDelegateCoordinator {
    var window: UIWindow
        
    init(windowScene: UIWindowScene) {
        self.window = UIWindow(windowScene: windowScene)
    }
    
    func start() {
        let weatherViewModel = WeatherViewModel()
        let weatherView = ViewController(viewModel: weatherViewModel)
        
        window.rootViewController = weatherView
        window.makeKeyAndVisible()
    }
}
