//
//  ViewController.swift
//  WeatherApp
//

import Combine
import CoreLocation
import UIKit

class ViewController: UIViewController {
    private let viewModel: WeatherViewModel
    private let locationManager = CLLocationManager()
    
    private lazy var txtCity: UITextField = {
        let field = UITextField()
        field.placeholder = "Enter city"
        field.borderStyle = .roundedRect
        field.returnKeyType = .search
        field.delegate = self
        field.clearButtonMode = .whileEditing
        return field
    }()
    
    private let lblError: UILabel = {
       let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .red
        label.textAlignment = .center
        return label
    }()
    private let lblTemperature = UILabel()
    private let lblHumidity = UILabel()
    private let lblDescription = UILabel()
    private let imgViewWeather = UIImageView()
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: WeatherViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        listenToViewModelChanges()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        lastSearchedCity()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addAutoLayoutSubView(txtCity)

        let searchButton = UIButton(type: .system)
        searchButton.setTitle("Search", for: .normal)
        searchButton.addTarget(self, action: #selector(searchCity), for: .touchUpInside)

        view.addAutoLayoutSubView(searchButton)

        view.addAutoLayoutSubView(lblTemperature)
        view.addAutoLayoutSubView(lblHumidity)
        view.addAutoLayoutSubView(lblDescription)
        view.addAutoLayoutSubView(imgViewWeather)
        view.addAutoLayoutSubView(lblError)

        // Layout
        NSLayoutConstraint.activate([
            txtCity.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            txtCity.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            txtCity.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            searchButton.topAnchor.constraint(equalTo: txtCity.bottomAnchor, constant: 10),
            searchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            lblTemperature.topAnchor.constraint(equalTo: searchButton.bottomAnchor, constant: 20),
            lblTemperature.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            lblHumidity.topAnchor.constraint(equalTo: lblTemperature.bottomAnchor, constant: 10),
            lblHumidity.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            lblDescription.topAnchor.constraint(equalTo: lblHumidity.bottomAnchor, constant: 10),
            lblDescription.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            imgViewWeather.topAnchor.constraint(equalTo: lblDescription.bottomAnchor, constant: 10),
            imgViewWeather.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imgViewWeather.widthAnchor.constraint(equalToConstant: 100),
            imgViewWeather.heightAnchor.constraint(equalToConstant: 100),
            
            lblError.topAnchor.constraint(equalTo: imgViewWeather.bottomAnchor, constant: 10),
            lblError.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            lblError.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            lblError.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc private func searchCity() {
        guard let city = txtCity.text, !city.isEmpty else {
            self.lblError.text = "Please enter a city."
            self.clearDataOnError()
            return
        }
        viewModel.fetchWeather(for: city)
    }

    private func listenToViewModelChanges() {
        viewModel.$weather
            .dropFirst()
            .sinkOnMain { [weak self] weatherResponse in
                self?.saveLastSearchedCity(self?.txtCity.text ?? "")
                guard let weather = weatherResponse else { return }
                self?.lblTemperature.text = "\(weather.main.temp) °F"
                self?.lblHumidity.text = "Humidity: \(weather.main.humidity)%"
                self?.lblDescription.text = weather.weatherDetail.first?.description.capitalized ?? ""
                
                if let url = URL(string: "https://openweathermap.org/img/wn/\(weather.weatherDetail.first?.icon ?? "")@2x.png") {
                    DispatchQueue.main.async {
                        self?.loadImage(from: url) { image in
                            DispatchQueue.main.async {
                                self?.imgViewWeather.image = image
                            }
                        }
                    }
                }
                self?.lblError.text = ""
            
        }.store(in: &cancellables)
        
        viewModel.$errorMsg
            .dropFirst()
            .sinkOnMain { [weak self] errorMsg in
                self?.lblError.text = errorMsg
                self?.clearDataOnError()
        }.store(in: &cancellables)
    }
    
    private func clearDataOnError() {
        lblTemperature.text = nil
        lblHumidity.text = nil
        lblDescription.text = nil
        imgViewWeather.image = nil
    }
    
    private func lastSearchedCity() {
        if let lastCity = UserDefaults.standard.string(forKey: "lastSearchedCity") {
            viewModel.fetchWeather(for: lastCity)
        }
    }
    
    private func saveLastSearchedCity(_ city: String) {
        UserDefaults.standard.set(city, forKey: "lastSearchedCity")
    }
    
    private func loadImage(from url: URL, completion: @escaping ((UIImage) -> Void)) {
        if let cachedImage = ImageCache.shared.object(forKey: url.absoluteString as NSString) {
            completion(cachedImage)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let image = UIImage(data: data) else { return }
            ImageCache.shared.setObject(image, forKey: url.absoluteString as NSString)
            completion(image)
        }.resume()
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            viewModel.getCityNameBy(latitude: Double(latitude), longitude: Double(longitude))
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        searchCity()
        return true
    }
}

extension Publisher where Self.Failure == Never {
    public func sinkOnMain(receiveValue: @escaping ((Self.Output) -> Void)) -> AnyCancellable {
        receive(on: DispatchQueue.main).sink(receiveValue: receiveValue)
    }
}

extension UIView {
    func addAutoLayoutSubView(_ subView: UIView) {
        subView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subView)
    }
}

