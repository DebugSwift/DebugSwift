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

        LocationManager.shared.didUpdate = { [weak self] value in
            self?.text.text = value
        }
    }

    @IBOutlet var text: UILabel!

    @IBAction func successMocked() {
        let random: Int = .random(in: 1...5)
        let url = "https://reqres.in/api/users?page=\(random)"
        RequestManager.mockRequest(url: url)
    }

    @IBAction func failureRequest() {
        let url = "https://reqres.in/api/users/23"
        RequestManager.mockRequest(url: url)
    }

    @IBAction func seeLocation() {
        LocationManager.shared.requestLocation()
    }
}
