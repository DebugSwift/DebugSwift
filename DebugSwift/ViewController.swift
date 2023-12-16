//
//  ViewController.swift
//  DebugSwift
//
//  Created by Matheus Gois on 2023/12/12.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigation()
    }

    fileprivate func setup() {
        title = "Increment View"
        view.backgroundColor = .white

        buildButton()
        FloatViewManager.setup(TabBarController())
        NetworkHelper.shared.enable()
    }

    fileprivate func buildButton() {
        if #available(iOS 13.0, *) {
            addLeftBarButton(image: .actions) {
                if FloatViewManager.isShowing() {
                    DispatchQueue.global().async {
                        self.mockRequest()
                    }
                } else {
                    FloatViewManager.show()
                }
            }
        }
    }

    private func setupNavigation() {
        navigationController?.navigationBar.tintColor = .systemBlue
    }

    private func mockRequest() {
        // Replace this URL with the actual endpoint you want to request
        let url = URL(string: "https://reqres.in/api/users?page=2")!

        // Create a URLSession object
        let session = URLSession.shared

        // Create a data task
        let task = session.dataTask(with: url) { (data, _, error) in
            // Check for errors
            if let error = error {
                print("Error: \(error)")
                return
            }

            // Check if data is available
            guard let data = data else {
                print("No data received")
                return
            }

            do {
                // Parse the JSON data
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                print("JSON Response: \(json)")
                DispatchQueue.main.async {
                    FloatViewManager.increment()
                }
            } catch {
                print("Error parsing JSON: \(error)")
            }
        }

        // Start the task
        task.resume()
    }
}
