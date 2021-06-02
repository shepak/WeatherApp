//
//  APIClient.swift
//  WeatherApp
//
//  Created by Mustafin Ruslan on 22.05.2021.
//

import Foundation

class APIClient{
    
    static let shared: APIClient = APIClient()
    
    let baseURL: String = "https://api.openweathermap.org/data/2.5/weather"
    let apiKey = "87609dd5e4e9eaf2aa8de7d39c4a266a"
    func getWheatherDateURL(lat: String, lon: String) -> String{
        
        return  "\(baseURL)?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"
        
    }
}

