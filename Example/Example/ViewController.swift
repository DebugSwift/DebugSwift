//
//  ViewController.swift
//  Example
//
//  Created by Matheus Gois on 16/12/23.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func successMocked() {
        let random: Int = .random(in: 1...5)
        let url = "https://reqres.in/api/users?page=\(random)"
        mockRequest(url: url)
    }

    @IBAction func failureRequest() {
        let url = "https://reqres.in/api/users/23"
        mockRequest(url: url)
    }

    func mockRequest(url: String) {
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
