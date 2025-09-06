//
//  Network.Controller.Detail.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation
import UIKit

final class NetworkViewControllerDetail: BaseController {
    private var model: HttpModel
    private var infos: [Config]
    private var filteredInfos: [Config] = []

    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor.black

        return tableView
    }()

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        return searchController
    }()

    init(model: HttpModel) {
        self.model = model
        self.infos = .init(model: model)
        super.init()
        setup()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        setupNavigation()
        setupSearch()
    }

    private func setupNavigation() {
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                image: UIImage(systemName: "square.and.arrow.up"),
                style: .plain,
                target: self,
                action: #selector(shareButtonTapped)
            ),
            UIBarButtonItem(
                image: UIImage(systemName: "doc.on.doc"),
                style: .plain,
                target: self,
                action: #selector(copyButtonTapped)
            ),
            UIBarButtonItem(
                title: "cURL",
                style: .plain,
                target: self,
                action: #selector(copyCurlButtonTapped)
            ),
            UIBarButtonItem(
                image: UIImage(systemName: "arrow.clockwise"),
                style: .plain,
                target: self,
                action: #selector(replayButtonTapped)
            )
        ]
    }

    private func setup() {
        title = "Details"
    }

    private func setupSearch() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
}

extension NetworkViewControllerDetail: UITableViewDelegate, UITableViewDataSource {
    private var _infos: [Config] {
        searchController.isActive ? filteredInfos : infos
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(
            NetworkTableViewCell.self,
            forCellReuseIdentifier: "NetworkCell"
        )
        tableView.register(
            NetworkTableViewCellDetail.self,
            forCellReuseIdentifier: "NetworkCellDetail"
        )
        view.backgroundColor = UIColor.black

        // Configure constraints for the tableView
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in _: UITableView) -> Int {
        _infos.count + 1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        1
    }

    func tableView(_: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        section == .zero ? .zero : UITableView.automaticDimension
    }

    func tableView(
        _: UITableView, viewForHeaderInSection section: Int
    ) -> UIView? {
        if section == .zero {
            return nil
        }
        let label = UILabel()
        label.backgroundColor = UIColor.black

        label.text = "    \(_infos[section - 1].title)"
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        return label
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == .zero {
            let cell =
                tableView.dequeueReusableCell(
                    withIdentifier: "NetworkCell",
                    for: indexPath
                ) as! NetworkTableViewCell
            cell.setup(model)

            return cell
        }
        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: "NetworkCellDetail",
                for: indexPath
            ) as! NetworkTableViewCellDetail

        cell.setup(_infos[indexPath.section - 1].description, searchController.searchBar.text)

        return cell
    }
}

extension NetworkViewControllerDetail: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }

        filteredInfos =
            searchText.isEmpty
                ? infos
                : infos.filter { $0.description.localizedCaseInsensitiveContains(searchText) }

        tableView.reloadData()
    }
}

// MARK: - Config

extension NetworkViewControllerDetail {
    struct Config {
        let title: String
        let description: String
    }
}

extension [NetworkViewControllerDetail.Config] {
    init(model: HttpModel) {
        var configs: [NetworkViewControllerDetail.Config] = [
            NetworkViewControllerDetail.Config(
                title: "TOTAL TIME",
                description: model.totalDuration ?? "No data"
            ),
            NetworkViewControllerDetail.Config(
                title: "REQUEST HEADER",
                description: model.requestHeaderFields?.formattedString() ?? "No data"
            ),
            NetworkViewControllerDetail.Config(
                title: "REQUEST",
                description: model.requestData?.formattedString() ?? "No data"
            ),
            NetworkViewControllerDetail.Config(
                title: "RESPONSE HEADER",
                description: model.responseHeaderFields?.formattedString() ?? "No data"
            ),
            NetworkViewControllerDetail.Config(
                title: "RESPONSE (RAW)",
                description: model.responseData?.formattedString() ?? "No data"
            )
        ]
        
        // Add decrypted response if available
        if model.isEncrypted && model.decryptedResponseData != nil {
            configs.append(NetworkViewControllerDetail.Config(
                title: "RESPONSE (DECRYPTED)",
                description: model.decryptedResponseData?.formattedString() ?? "No data"
            ))
            configs.append(NetworkViewControllerDetail.Config(
                title: "ENCRYPTION STATUS",
                description: "🔓 Response was encrypted and successfully decrypted"
            ))
        } else if model.isEncrypted {
            configs.append(NetworkViewControllerDetail.Config(
                title: "ENCRYPTION STATUS",
                description: "🔒 Response is encrypted (no decryption key available)"
            ))
        }
        
        configs.append(contentsOf: [
            NetworkViewControllerDetail.Config(
                title: "RESPONSE SIZE",
                description: model.responseData?.formattedSize() ?? "No data"
            ),
            NetworkViewControllerDetail.Config(
                title: "MIME TYPE",
                description: model.mineType ?? "No data"
            )
        ])
        
        self = configs
    }
}

extension NetworkViewControllerDetail {
    @objc private func copyButtonTapped() {
        UIPasteboard.general.string = formatLog(model: model)
    }

    @objc private func shareButtonTapped() {
        let logText = formatLog(model: model)

        var fileName = model.url?.path.replacingOccurrences(of: "/", with: "-") ?? "-log"
        fileName.removeFirst()

        FileSharingManager.generateFileAndShare(text: logText, fileName: fileName)
    }

    @objc private func copyCurlButtonTapped() {
        let curlCommand = """
            curl -X \(model.method ?? "") \\
                 -H "\(model.requestHeaderFields?.formattedCurlString() ?? "")" \\
                 -d "\(model.requestData?.formattedCurlString() ?? "")" \\
                 \(model.url?.absoluteString ?? "")
        """
        UIPasteboard.general.string = curlCommand
    }
    
    @objc private func replayButtonTapped() {
        showReplayConfirmation()
    }
    
    private func showReplayConfirmation() {
        let alert = UIAlertController(
            title: "Replay Request",
            message: "Do you want to resend this HTTP request?\n\n\(model.method ?? "GET") \(model.url?.absoluteString ?? "")",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Replay", style: .default) { [weak self] _ in
            self?.performRequestReplay()
        })
        
        present(alert, animated: true)
    }
    
    private func performRequestReplay() {
        guard let url = model.url,
              let method = model.method else {
            showErrorAlert("Invalid request data")
            return
        }
        
        // Show loading indicator
        let loadingAlert = UIAlertController(title: "Sending Request...", message: nil, preferredStyle: .alert)
        present(loadingAlert, animated: true)
        
        // Create request with same parameters
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Add headers
        if let headers = model.requestHeaderFields {
            for (key, value) in headers {
                if let stringValue = value as? String {
                    request.setValue(stringValue, forHTTPHeaderField: key)
                }
            }
        }
        
        // Add body data
        request.httpBody = model.requestData
        
        // Perform request
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                loadingAlert.dismiss(animated: false) {
                    self?.handleReplayResponse(data: data, response: response, error: error)
                }
            }
        }.resume()
    }
    
    private func handleReplayResponse(data: Data?, response: URLResponse?, error: Error?) {
        var title = "Request Replayed"
        var message = ""
        
        if let error = error {
            title = "Replay Failed"
            message = "Error: \(error.localizedDescription)"
        } else if let httpResponse = response as? HTTPURLResponse {
            let statusCode = httpResponse.statusCode
            let responseSize = data?.count ?? 0
            
            message = """
            Status Code: \(statusCode)
            Response Size: \(formatBytes(responseSize))
            """
            
            if statusCode >= 200 && statusCode < 300 {
                title = "Replay Successful ✅"
            } else if statusCode >= 400 {
                title = "Replay Completed ⚠️"
            }
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add response viewing option if we have data
        if let data = data, !data.isEmpty {
            alert.addAction(UIAlertAction(title: "View Response", style: .default) { [weak self] _ in
                self?.showReplayResponseDetail(data: data, response: response)
            })
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showReplayResponseDetail(data: Data, response: URLResponse?) {
        let detailVC = ReplayResponseViewController(data: data, response: response)
        let navController = UINavigationController(rootViewController: detailVC)
        present(navController, animated: true)
    }
    
    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private func formatLog(
        model: HttpModel
    ) -> String {
        return """
        [\(model.method ?? "")] \(model.startTime ?? "") (\(model.statusCode ?? ""))

        ------- URL -------
        \(model.url?.absoluteString ?? "No data")

        ------- REQUEST HEADER -------
        \(model.requestHeaderFields?.formattedString() ?? "No data")

        ------- REQUEST -------
        \(model.requestData?.formattedString() ?? "No data")

        ------- RESPONSE HEADER -------
        \(model.responseHeaderFields?.formattedString() ?? "No data")

        ------- RESPONSE -------
        \(model.responseData?.formattedString() ?? "No data")

        ------- RESPONSE SIZE -------
        \(model.responseData?.formattedSize() ?? "No data")

        ------- TOTAL TIME -------
        \(model.totalDuration ?? "No data")

        ------- MIME TYPE -------
        \(model.mineType ?? "No data")
        """
    }
}

// MARK: - Replay Response Viewer

final class ReplayResponseViewController: BaseController {
    private let data: Data
    private let response: URLResponse?
    
    private let textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .black
        textView.textColor = .white
        textView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.isEditable = false
        return textView
    }()
    
    init(data: Data, response: URLResponse?) {
        self.data = data
        self.response = response
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        displayResponse()
    }
    
    private func setupUI() {
        title = "Replay Response"
        view.backgroundColor = .black
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(closeTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareTapped)
        )
        
        view.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func displayResponse() {
        var responseText = ""
        
        // Headers
        if let httpResponse = response as? HTTPURLResponse {
            responseText += "HTTP/1.1 \(httpResponse.statusCode)\n"
            responseText += "Headers:\n"
            for (key, value) in httpResponse.allHeaderFields {
                responseText += "\(key): \(value)\n"
            }
            responseText += "\n"
        }
        
        // Body
        responseText += "Response Body:\n"
        responseText += "═══════════════════════════════════════\n"
        
        let formattedString = data.formattedString()
        textView.text = responseText + formattedString
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func shareTapped() {
        let text = textView.text ?? ""
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        present(activityVC, animated: true)
    }
}
