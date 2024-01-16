//
//  LogsViewController.swift
//  DebugSwift
//
//  Created by Matheus Gois on 20/12/23.
//

import UIKit

final class LogsViewController: BaseController {

    // MARK: - Properties

    private let textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textColor = .white
        textView.font = .systemFont(ofSize: 10)
        return textView
    }()

    // MARK: - Initialization

    init(text: String) {
        textView.text = text
        super.init()
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - UI Setup

    private func setupUI() {
        title = "logs".localized()
        view.backgroundColor = .black

        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 20
            ),
            textView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -20
            ),
            textView.topAnchor.constraint(
                equalTo: view.topAnchor,
                constant: 200
            ),
            textView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -100
            )
        ])
    }
}
