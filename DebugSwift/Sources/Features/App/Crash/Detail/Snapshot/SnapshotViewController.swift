//
//  SnapshotViewController.swift
//  DebugSwift
//
//  Created by Matheus Gois on 20/12/23.
//

import UIKit

class SnapshotViewController: BaseController {

    // MARK: - Properties

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    // MARK: - Initialization

    init(image: UIImage) {
        imageView.image = image
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - UI Setup

    private func setupUI() {
        title = "Snapshot"
        view.backgroundColor = .black

        view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 20
            ),
            imageView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -20
            ),
            imageView.topAnchor.constraint(
                equalTo: view.topAnchor,
                constant: 200
            ),
            imageView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -100
            )
        ])

        imageView.layer.cornerRadius = 12
        imageView.layer.masksToBounds = true
    }
}
