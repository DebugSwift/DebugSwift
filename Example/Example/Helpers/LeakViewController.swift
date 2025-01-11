//
//  LeakViewController.swift
//  Example
//
//  Created by Matheus Gois on 16/05/24.
//

import UIKit
class LeakViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemOrange

        let imageView = UIImageView(image: UIImage(systemName: "drop.triangle"))
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        imageView.center = view.center
        imageView.tintColor = .black
        view.addSubview(imageView)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        DispatchQueue.main.asyncAfter(wallDeadline: .now() + 10) {
            // Leak
            print(self)
        }
    }
}
