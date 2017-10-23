//
//  ViewController.swift
//  WeatherApp
//
//  Created by Angela Yu on 23/08/2015.
//  Copyright (c) 2015 London App Brewery. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire
import SwiftyJSON

class WeatherViewController: UIViewController, CLLocationManagerDelegate, ChangeCityDelegate {
    
    //Constants
    let WEATHER_URL = "http://api.openweathermap.org/data/2.5/weather"
    let APP_ID = "e72ca729af228beabd5d20e3b7749713"
    
    let locationManager = CLLocationManager()
    let weatherDataModel = WeatherDataModel()
    var toggleChangeUnit: Int = 0
    var receivedTemp: Int = 0

    //Pre-linked IBOutlets
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!

    @IBAction func onChangeUnitClick(_ sender: Any) {
        toggleChangeUnit = toggleChangeUnit + 1
        if toggleChangeUnit == 1 {
            transformKtoF()
        } else if toggleChangeUnit == 2 {
            transformKtoC()
        } else if toggleChangeUnit == 3 {
            transformNothing()
        }
        print(toggleChangeUnit)
    }
    
    func transformKtoF() {
        weatherDataModel.temperature = receivedTemp * 9/5 - Int(459.67)
        updateUI(format: "℉")
    }
    
    func transformKtoC() {
        weatherDataModel.temperature = receivedTemp - Int(273.15)
        updateUI(format: "℃")
    }
    
    func transformNothing() {
        toggleChangeUnit = 0
        weatherDataModel.temperature = receivedTemp
        updateUI(format: "°")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    //MARK: - Networking
    /***************************************************************/
    
    func getWeatherData(url: String, parameters: [String : String]) {
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON {
            response in
            if response.result.isSuccess {
                print("Success! Got the weather data")
                let weatherJSON = JSON(response.result.value!)
                self.updateWeatherData(json: weatherJSON)
            } else {
                print("error \(response.result.error)")
                self.cityLabel.text = "Connection issues"
            }
        }
    }
    
    //MARK: - JSON Parsing
    /***************************************************************/
   
    func updateWeatherData(json: JSON) {
        print(json)
        if let tempResult = json["main"]["temp"].double {
            receivedTemp = Int(tempResult)
            
            weatherDataModel.temperature = Int(tempResult)
            weatherDataModel.city = json["name"].stringValue
            weatherDataModel.condition = json["weather"][0]["id"].intValue
            weatherDataModel.weatherIconName = weatherDataModel.updateWeatherIcon(condition:
                weatherDataModel.condition)
            updateUI(format: "°")
        } else {
            self.cityLabel.text = "Error on fetching data"
            self.temperatureLabel.text = "--"
        }
    }
    
    //MARK: - UI Updates
    /***************************************************************/
    func updateUI(format: String) {
        cityLabel.text = weatherDataModel.city
        temperatureLabel.text = "\(weatherDataModel.temperature) \(format)"
        weatherIcon.image = UIImage(named: weatherDataModel.weatherIconName)
    }
    
    //MARK: - Location Manager Delegate Methods
    /***************************************************************/
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[locations.count - 1]
        if location.horizontalAccuracy > 0 {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            
            print("lng = \(location.coordinate.longitude), lat = \(location.coordinate.latitude)")
            
            let lat = String(location.coordinate.latitude)
            let lng = String(location.coordinate.longitude)
            
            let params : [String : String] = ["lat" : lat, "lon" : lng, "appid" : APP_ID]
            
            getWeatherData(url: WEATHER_URL, parameters: params)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        cityLabel.text = "Location Unavailable"
    }

    //MARK: - Change City Delegate methods
    /***************************************************************/
    
    func userEnteredANewCityName(city: String) {
        let params: [String : String] = ["q" : city, "appid" : APP_ID]
        
        getWeatherData(url: WEATHER_URL, parameters: params)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "changeCityName" {
            let destinationVC = segue.destination as! ChangeCityViewController
            
            destinationVC.delegate = self
        }
    }
    
    
    
    
}


