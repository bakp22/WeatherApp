//
//  ViewController.swift
//  WeatherApp
//
//  Created by Beren Akpinar on 9/2/24.
//

import UIKit


class MyButton: UIButton {
    var action: (() -> Void)?

    func whenButtonIsClicked(action: @escaping () -> Void) {
        self.action = action
        self.addTarget(self, action: #selector(MyButton.clicked), for: .touchUpInside)
    }

    // Button Event Handler:
    @objc func clicked() {
        action?()
    }
}

class ViewController: UIViewController {
    // MARK: - UI
    
    private var weather: WeatherInfo?
    
    private lazy var pmlabel: UILabel = {
        let pm = UILabel()
        pm.translatesAutoresizingMaskIntoConstraints = false
        pm.layer.borderWidth = 2
        return pm
    }()
    
    private lazy var button: MyButton = {
        let button = MyButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.configuration = .filled()
        let title = NSAttributedString(string: "Get Temp", attributes: [.font: UIFont.systemFont(ofSize: 18, weight: .bold)])
        button.setAttributedTitle(title, for: .normal)
        return button
    }()
    
    private lazy var label: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private lazy var textField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false // FOR AUTOLAYOUT TO WORK
        tf.layer.borderWidth = 2
        tf.placeholder = "Pick a city"
        
        return tf
    }()
    
    private lazy var tempLabel: UILabel = {
        let lbl2 = UILabel()
        lbl2.translatesAutoresizingMaskIntoConstraints = false
        return lbl2
    }()
    
    // MARK: - Lifecycle
    override func loadView() {
        super.loadView()
        setup()
        
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        label.text = "The Weather App by Beren Akpinar"
        pmlabel.text = "PM Accelerator is designed to support PMs"
        
        if let temp = weather?.temperature {
            if temp.isNaN {
                print("Temperature is NaN")
            } else {
                print("Temperature: \(temp)")
            }
        } else {
            print("Weather or temperature is nil")
        }
        
        let temp = weather?.temperature ?? 0
        tempLabel.text = String(temp)
        
        self.view.backgroundColor = .white
        
        //When the button is clicked to retrieve the temp I need to find a way to access location and get API call data
        button.whenButtonIsClicked {
            
            guard let city = self.textField.text, !city.isEmpty else {
                            print("City text field is empty")
                            return
                        }
            

            Task{
                do {
                    let city = self.textField.text ?? "defaultCity"
                    let temperature = try await getWeatherInfo(for: city)
                    let converted = (temperature * (9/5)) + 32
                    self.tempLabel.text = "\(converted)°F"
                } catch GHError.invalidURL{
                    print("invalid url")
                } catch GHError.invalidData{
                    print("invalid data")
                } catch GHError.invalidResponse{
                    print("invalid response")
                } catch {
                    print("unexpected error")
                }
            }
        }
        
    }
    
}


private extension ViewController{
    
    func setup(){
        
        self.view.addSubview(textField)
        self.view.addSubview(label)
        self.view.addSubview(tempLabel)
        self.view.addSubview(button)
        self.view.addSubview(pmlabel)
       
        
        //constraints for textfield
        NSLayoutConstraint.activate([
            textField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textField.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            textField.widthAnchor.constraint(equalToConstant: 200),
            textField.heightAnchor.constraint(equalToConstant: 100),
            
        ])
        
        //constraints for label
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 20),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -150),
            label.widthAnchor.constraint(equalToConstant: 400),
            label.heightAnchor.constraint(equalToConstant: 400),
        
        ])
        
        NSLayoutConstraint.activate([
            tempLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 50),
            tempLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 150),
            tempLabel.widthAnchor.constraint(equalToConstant: 200),
            tempLabel.heightAnchor.constraint(equalToConstant: 400),
        
        ])
        
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
            button.heightAnchor.constraint(equalToConstant: 40),
            button.widthAnchor.constraint(equalToConstant: 150),
        
        ])
        
        NSLayoutConstraint.activate([
            pmlabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 5),
            pmlabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -250),
            pmlabel.widthAnchor.constraint(equalToConstant: 350),
            pmlabel.heightAnchor.constraint(equalToConstant: 50),
        ])
        
    }
}



//FOR API CALL TO RECIEVE TEMPERATURE -- network call
func getWeatherInfo(for city: String) async throws -> Double {
    let apiKey = "zuoQ7ZfJhcP6dtlIMdYJlw2YMcozwljj"
    let endpoint = "https://api.tomorrow.io/v4/weather/realtime"

    
    guard var urlComponents = URLComponents(string: endpoint) else {
        throw GHError.invalidURL
    } //returns url object
    
    urlComponents.queryItems = [
        URLQueryItem(name: "location", value: city),
        URLQueryItem(name: "apikey", value: apiKey),
        URLQueryItem(name: "units", value: "metric")
    ]
    
    
    guard let url = urlComponents.url else {
        throw GHError.invalidURL
    }
    
    var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    
    //making network calls
    let (data, response) = try await URLSession.shared.data(from: url) //GET REQUEST
    
    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw GHError.invalidResponse
    }
    
    do {
        let decoder = JSONDecoder()
        let weatherResponse = try decoder.decode(WeatherResponse.self, from: data)
        return weatherResponse.data.values.temperature
    } catch{
        print("Decoding error: \(error)")
        throw GHError.invalidData
    }
}





//locate city from json file
func loadCities(from fileName: String) -> [City] {
    guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: "json") else {
        print("File not found")
        return []
    }
    
    do {

        let data = try Data(contentsOf: fileURL)
        
        
        let cities = try JSONDecoder().decode([City].self, from: data)
        return cities
    } catch {
    
        print("Error loading or parsing the file: \(error.localizedDescription)")
        print("Detailed Error: \(error)")
        return []
    }
}


    

struct WeatherInfo: Codable {
    let temperature: Double
}

struct WeatherData: Codable {
    let time: String
    let values: WeatherInfo
}

struct WeatherResponse: Codable {
    let data: WeatherData
    let location: LocationInfo
}

struct LocationInfo: Codable {
    let lat: Double
    let lon: Double
    let name: String
    let type: String
}


struct City: Decodable {
    let name: String
}

enum GHError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
}

