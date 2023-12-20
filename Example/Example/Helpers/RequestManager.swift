//
//  RequestManager.swift
//  Example
//
//  Created by Matheus Gois on 19/12/23.
//

import Foundation

enum RequestManager {
    static func mockRequest(url: String) {
        let url = URL(string: url)!

        let session = URLSession.shared

        let task = session.dataTask(with: url) { data, _, error in
            if let error {
                print("Error: \(error)")
                return
            }

            guard let data else {
                print("No data received")
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                print("JSON Response: \(json)")
            } catch {
                print("Error parsing JSON: \(error)")
            }
        }

        task.resume()
    }
}
