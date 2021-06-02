//
//  ViewController.swift
//  WeatherApp
//
//  Created by Mustafin Ruslan on 21.05.2021.
//

import UIKit

import Alamofire

import CoreLocation

import SwiftyJSON

class ViewController: UIViewController {

    @IBOutlet weak var CityNameLabel: UILabel!
    
    @IBOutlet weak var temperatureLabel: UILabel!
    
    @IBOutlet weak var humidityLabel: UILabel!
    
    @IBOutlet weak var windSpeedLabel: UILabel!
    
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        locationManager.requestLocation()
        
    }

    func getWeatherwithAlamofire(lat: String, long:String){
        
        guard let url = URL(string: APIClient.shared.getWheatherDateURL(lat: lat, lon: long)) else{
            print("could not form url")
            return
        }
        
        let headers: HTTPHeaders = [
            "Accept": "application/json"
            
        ]
        
        let parameters: Parameters = [:]
        
        AF.request(url, method: HTTPMethod.get, parameters: parameters, encoding: URLEncoding.default, headers: headers, interceptor: nil, requestModifier: nil).responseJSON { [weak self](response) in
            
            guard let strongSelf = self else{return}
            guard let data = response.data else{return}
           
            DispatchQueue.main.async {
                strongSelf.parseJSONWithCodable(data: data)
            }
            
            
//            if let jsonData = response.value as? [String : Any]{
//
//                DispatchQueue.main.async {
//                    strongSelf.parseJSONWithSwifty(data: jsonData)
//                }
//
//
//            }
        }
        
//        AF.request(url).validate().responseJSON { (response) in
//            if let jsonData = response.value as? [String : Any]{
//                print(jsonData)
//            }
//        }
    }
    
    func parseJSONWithCodable(data:Data){
        
        do{
            
            let weatherObject = try JSONDecoder().decode(WeatherModel.self, from: data)
            
            humidityLabel.text = "\(weatherObject.humidity)"
            CityNameLabel.text = weatherObject.name
            temperatureLabel.text = "\(Int(weatherObject.temp))°"
            windSpeedLabel.text = "\(weatherObject.windSpeed)"
            
            
        }catch let error as NSError{
            
            print(error.localizedDescription)
            
        }
        
        
        
        
        
    }
    
    
    func parseJSONWithSwifty(data: [String:Any]){
      
        let jsonData = JSON(data)
        
        if let humidity = jsonData["main"]["humidity"].int{
            humidityLabel.text = "\(humidity)"
        }
        if let temp = jsonData["main"]["temp"].double{
            temperatureLabel.text = "\(Int(temp))°"
        }
        if let wind = jsonData["wind"]["speed"].double{
            windSpeedLabel.text = "\(wind)"
        }
        if let name = jsonData["name"].string{
            CityNameLabel.text = name
        }
    }
    
    func parseJSONManually(data:[String:Any]){
        
        if let main = data["main"] as? [String:Any]{
            if let humidity = main["humidity"] as? Int{
                humidityLabel.text = "\(humidity)"
            }
            if let temp = main["temp"] as? Double{
                temperatureLabel.text = "\(Int(temp))°"
            }
        }
        if let wind = data["wind"] as? [String: Any]{
            if let windspeed = wind["speed"] as? Double{
                windSpeedLabel.text = "\(windspeed)"
            }
        }
        if let name = data["name"] as? String{
            CityNameLabel.text = name
        }
        
        
    }
    
    func getWeatherWithURLSession(lat: String, long: String){
       
        let apiKey = APIClient.shared.apiKey
        
        if var urlComponents = URLComponents(string: APIClient.shared.baseURL){
            urlComponents.query = "lat=\(lat)&lon=\(long)&appid=\(apiKey)"
            
            guard let url = urlComponents.url else {return}
            
            var request = URLRequest(url: url)
            
            request.httpMethod = "GET"
            request.addValue("application/json; charset=utf8", forHTTPHeaderField: "Accept")
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)
            let task = session.dataTask(with: request) { (data, response, error) in
                if let error = error{
                    print(error.localizedDescription)
                    return
                }
                guard let data = data else{return}
                
                do{
                   
                    guard let weatherData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else{
                        print("there was an error converting data into JSON")
                        return
                    }
                    print (weatherData)
                    
                }catch{
                    print("error converting data into JSON")
                }
                
                
            }
        task.resume()
        }
        
        /*
        guard let weatherURL = URL(string: APIClient.shared.getWheatherDateURL(lat: lat, lon: long)) else {return}
        URLSession.shared.dataTask(with: weatherURL) { (data, response, error) in
            if let error = error{
                print(error.localizedDescription)
                return
            }
            guard let data = data else{return}
            
            do{
               
                guard let weatherData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else{
                    print("there was an error converting data into JSON")
                    return
                }
                print (weatherData)
                
            }catch{
                print("error converting data into JSON")
            }
            
            
        }.resume()
        
        */
    }
    
    
}

extension ViewController: CLLocationManagerDelegate{
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first{
            
            let latitude = String(location.coordinate.latitude)
            
            let longitude = String(location.coordinate.longitude)
            
            print(latitude)
            print(longitude)
            
            getWeatherwithAlamofire(lat: latitude, long: longitude)
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status{
        
        case .notDetermined:
            
            locationManager.requestWhenInUseAuthorization()
            break
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
            break
        case .denied, .restricted:
            
            let alertController = UIAlertController(title: "Location Access Disabled", message: "Weather Appp needs your location to give a weather forecast",preferredStyle: .alert)
            let cancelAction = UIAlertAction( title: "Cancel", style: .cancel) { (action) in
                alertController.dismiss(animated: true, completion: nil)
            }
            alertController.addAction(cancelAction)
            
            let settings = UIAlertAction( title: "Settings", style: .default) { (action) in
                if let url = URL(string: UIApplication.openSettingsURLString){
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
            alertController.addAction(settings)
            present(alertController, animated: true, completion: nil)
            break
        }
    }
}
