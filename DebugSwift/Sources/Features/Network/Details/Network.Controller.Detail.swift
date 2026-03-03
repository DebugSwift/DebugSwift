//
//  Network.Controller.Detail.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation
import UIKit

final class NetworkViewControllerDetail: BaseTableController {
    private var model: HttpModel
    private var sections: [DetailSection] = []
    private var filteredSections: [DetailSection] = []
    private var searchController: UISearchController?

    init(model: HttpModel) {
        self.model = model
        super.init()
        self.sections = DetailSection.buildSections(from: model)
        self.filteredSections = self.sections
        setup()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavigation()
        setupSearch()
    }

    private func setupNavigation() {
        title = "Request Details"
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                image: injectionSymbolImage(),
                style: .plain,
                target: self,
                action: #selector(configureInjectionForEndpoint)
            ),
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

    private func injectionSymbolImage() -> UIImage? {
        if #available(iOS 16.0, *) {
            return UIImage(systemName: "syringe")
        }

        return UIImage(systemName: "pencil")
    }
    
    @objc private func configureInjectionForEndpoint() {
        guard let url = model.url else { return }
        
        let alertController = UIAlertController(
            title: "Configure Injection",
            message: "Configure delay or failure injection for:\n\(url.host ?? url.absoluteString)",
            preferredStyle: .actionSheet
        )
        
        // Quick delay options
        alertController.addAction(UIAlertAction(title: "Add 2s Delay", style: .default) { [weak self] _ in
            self?.applyDelayToEndpoint(delay: 2.0)
        })
        
        alertController.addAction(UIAlertAction(title: "Add 5s Delay", style: .default) { [weak self] _ in
            self?.applyDelayToEndpoint(delay: 5.0)
        })
        
        // Quick failure options
        alertController.addAction(UIAlertAction(title: "Inject Timeout (100%)", style: .default) { [weak self] _ in
            self?.applyFailureToEndpoint(type: .timeout)
        })
        
        alertController.addAction(UIAlertAction(title: "Inject HTTP 404 (100%)", style: .default) { [weak self] _ in
            self?.applyHTTPErrorToEndpoint(statusCode: 404)
        })
        
        alertController.addAction(UIAlertAction(title: "Inject HTTP 500 (100%)", style: .default) { [weak self] _ in
            self?.applyHTTPErrorToEndpoint(statusCode: 500)
        })
        
        // Advanced settings
        alertController.addAction(UIAlertAction(title: "Advanced Settings...", style: .default) { [weak self] _ in
            let settingsController = NetworkInjectionSettingsController()
            self?.navigationController?.pushViewController(settingsController, animated: true)
        })
        
        // Clear injection
        alertController.addAction(UIAlertAction(title: "Clear All Injection", style: .destructive) { [weak self] _ in
            self?.clearInjectionForEndpoint()
        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alertController, animated: true)
    }
    
    private func applyDelayToEndpoint(delay: TimeInterval) {
        guard let url = model.url else { return }
        let urlPattern = url.host ?? url.absoluteString
        
        var config = NetworkInjectionManager.shared.getDelayConfig()
        config.isEnabled = true
        config.fixedDelay = delay
        config.urlPatterns = [urlPattern]
        config.httpMethods = model.method.map { [$0] } ?? []
        
        NetworkInjectionManager.shared.setDelayConfig(config)
        
        showAlert(
            with: "Injection Applied",
            title: String(format: "%.1fs delay applied to \(urlPattern)", delay),
            rightButtonTitle: "OK"
        )
    }
    
    private func applyFailureToEndpoint(type: NetworkFailureConfig.FailureType) {
        guard let url = model.url else { return }
        let urlPattern = url.host ?? url.absoluteString
        
        var config = NetworkInjectionManager.shared.getFailureConfig()
        config.isEnabled = true
        config.failureRate = 1.0
        config.failureType = type
        config.urlPatterns = [urlPattern]
        config.httpMethods = model.method.map { [$0] } ?? []
        
        NetworkInjectionManager.shared.setFailureConfig(config)
        
        showAlert(
            with: "Injection Applied",
            title: "Failure injection applied to \(urlPattern)",
            rightButtonTitle: "OK"
        )
    }
    
    private func applyHTTPErrorToEndpoint(statusCode: Int) {
        guard let url = model.url else { return }
        let urlPattern = url.host ?? url.absoluteString
        
        var config = NetworkInjectionManager.shared.getFailureConfig()
        config.isEnabled = true
        config.failureRate = 1.0
        config.failureType = .httpError(statusCode: nil)
        config.urlPatterns = [urlPattern]
        config.httpMethods = model.method.map { [$0] } ?? []
        config.customStatusCodes = [statusCode]
        
        NetworkInjectionManager.shared.setFailureConfig(config)
        
        showAlert(
            with: "Injection Applied",
            title: "HTTP \(statusCode) error injection applied to \(urlPattern)",
            rightButtonTitle: "OK"
        )
    }
    
    private func clearInjectionForEndpoint() {
        var delayConfig = NetworkInjectionManager.shared.getDelayConfig()
        delayConfig.isEnabled = false
        NetworkInjectionManager.shared.setDelayConfig(delayConfig)
        
        var failureConfig = NetworkInjectionManager.shared.getFailureConfig()
        failureConfig.isEnabled = false
        NetworkInjectionManager.shared.setFailureConfig(failureConfig)
        
        showAlert(
            with: "Injection Cleared",
            title: "All network injection has been disabled",
            rightButtonTitle: "OK"
        )
    }

    private func setup() {
        title = "Details"
    }

    private func setupSearch() {
        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search all details..."
        search.hidesNavigationBarDuringPresentation = false
        
        navigationItem.searchController = search
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        
        searchController = search
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(DetailInfoCell.self, forCellReuseIdentifier: "DetailInfoCell")
        tableView.register(DetailNavigationCell.self, forCellReuseIdentifier: "DetailNavigationCell")
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = .darkGray
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        tableView.addGestureRecognizer(longPress)
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        filteredSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredSections[section].items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = filteredSections[indexPath.section].items[indexPath.row]
        
        switch item.type {
        case .info:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DetailInfoCell", for: indexPath) as! DetailInfoCell
            cell.configure(title: item.title, value: item.value ?? "No data")
            return cell
        case .navigation:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DetailNavigationCell", for: indexPath) as! DetailNavigationCell
            cell.configure(title: item.title, badge: item.badge)
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        filteredSections[section].title?.isEmpty == false ? filteredSections[section].title : nil
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = filteredSections[indexPath.section].items[indexPath.row]
        
        guard item.type == .navigation else { return }
        
        switch item.action {
        case .showRequestHeaders:
            showHeaders(model.requestHeaderFields, title: "Request Headers")
        case .showResponseHeaders:
            showHeaders(model.responseHeaderFields, title: "Response Headers")
        case .showRequestBody:
            showBody(model.requestData, title: "Request Body", isRequest: true)
        case .showRequestBodyRaw:
            showRawBody(model.requestData, title: "Raw Request", headers: model.requestHeaderFields, isRequest: true)
        case .showResponseBody:
            showBody(model.decryptedResponseData ?? model.responseData, title: model.isEncrypted && model.decryptedResponseData != nil ? "Response Body (Decrypted)" : "Response Body", isRequest: false)
        case .showResponseBodyRaw:
            showRawBody(model.decryptedResponseData ?? model.responseData, title: model.isEncrypted && model.decryptedResponseData != nil ? "Raw Response (Decrypted)" : "Raw Response", headers: model.responseHeaderFields, isRequest: false)
        case .none:
            break
        }
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        let point = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point) else { return }
        
        let item = filteredSections[indexPath.section].items[indexPath.row]
        guard item.type == .info,
              let value = item.value,
              !value.isEmpty else { return }
        
        UIPasteboard.general.string = value
        showToast(message: "Copied to clipboard")
    }

    private func showHeaders(_ headers: [String: Any]?, title: String) {
        let vc = HeadersViewController(headers: headers, title: title)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func showBody(_ data: Data?, title: String, isRequest: Bool) {
        let vc = BodyBrowserViewController(data: data, title: title, isRequest: isRequest)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func showRawBody(_ data: Data?, title: String, headers: [String: Any]?, isRequest: Bool) {
        let vc = RawBodyViewController(data: data, headers: headers, title: title, isRequest: isRequest)
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Detail Section Models

extension NetworkViewControllerDetail {
    enum ItemType {
        case info
        case navigation
    }
    
    enum ItemAction {
        case showRequestHeaders
        case showResponseHeaders
        case showRequestBody
        case showRequestBodyRaw
        case showResponseBody
        case showResponseBodyRaw
    }
    
    struct DetailItem {
        let title: String
        let value: String?
        let type: ItemType
        let action: ItemAction?
        let badge: String?
        
        init(title: String, value: String, type: ItemType = .info) {
            self.title = title
            self.value = value
            self.type = type
            self.action = nil
            self.badge = nil
        }
        
        init(title: String, action: ItemAction, badge: String? = nil) {
            self.title = title
            self.value = nil
            self.type = .navigation
            self.action = action
            self.badge = badge
        }
    }
    
    struct DetailSection {
        let title: String?
        let items: [DetailItem]
        
        static func buildSections(from model: HttpModel) -> [DetailSection] {
            var sections: [DetailSection] = []
            
            // Basic info section
            var basicItems: [DetailItem] = []
            
            if let method = model.method {
                basicItems.append(DetailItem(title: "METHOD", value: method))
            }
            
            if let host = model.url?.host {
                basicItems.append(DetailItem(title: "HOST", value: host))
            }
            
            if let path = model.url?.path, !path.isEmpty {
                basicItems.append(DetailItem(title: "PATH", value: path))
            }
            
            if let statusCode = model.statusCode {
                basicItems.append(DetailItem(title: "STATUS CODE", value: statusCode))
            }
            
            // Check connection type
            if let headers = model.responseHeaderFields {
                let connectionType = detectConnectionType(headers: headers)
                if !connectionType.isEmpty {
                    basicItems.append(DetailItem(title: "CONNECTION TYPE", value: connectionType))
    }
}

            // Stream status for SSE
            if isServerSentEvent(model: model) {
                basicItems.append(DetailItem(title: "STREAM STATUS", value: "Completed"))
                let eventCount = countSSEEvents(data: model.responseData)
                basicItems.append(DetailItem(title: "TOTAL EVENTS", value: "\(eventCount)"))
            }
            
            if !basicItems.isEmpty {
                sections.append(DetailSection(title: "GENERAL", items: basicItems))
}

            // Request section
            let requestHeadersCount = model.requestHeaderFields?.count ?? 0
            var requestItems: [DetailItem] = [
                DetailItem(title: "Request Headers", action: .showRequestHeaders, badge: "\(requestHeadersCount)"),
            ]
            
            if let requestData = model.requestData, !requestData.isEmpty {
                let bodyCount = countBodyItems(data: requestData)
                let badge = bodyCount > 0 ? "\(bodyCount)" : nil
                requestItems.append(DetailItem(title: "Browse Request Body", action: .showRequestBody, badge: badge))
                requestItems.append(DetailItem(title: "Raw Request", action: .showRequestBodyRaw))
    }
    
            sections.append(DetailSection(title: "REQUEST", items: requestItems))
            
            // Response section
            let responseHeadersCount = model.responseHeaderFields?.count ?? 0
            var responseItems: [DetailItem] = [
                DetailItem(title: "Response Headers", action: .showResponseHeaders, badge: "\(responseHeadersCount)"),
            ]
            
            let responseDataToUse = model.decryptedResponseData ?? model.responseData
            if let responseData = responseDataToUse, !responseData.isEmpty {
                let bodyCount = countBodyItems(data: responseData)
                let badge = bodyCount > 0 ? "\(bodyCount)" : nil
                responseItems.append(DetailItem(title: "Browse Response Body", action: .showResponseBody, badge: badge))
                responseItems.append(DetailItem(title: "Raw Response", action: .showResponseBodyRaw))
            }
            
            sections.append(DetailSection(title: "RESPONSE", items: responseItems))
            
            // Additional info section
            var additionalItems: [DetailItem] = []
            
            if let totalTime = model.totalDuration {
                additionalItems.append(DetailItem(title: "TOTAL TIME", value: totalTime))
            }
            
            if let size = model.responseData?.formattedSize() {
                additionalItems.append(DetailItem(title: "RESPONSE SIZE", value: size))
            }
            
            if let mimeType = model.mineType {
                additionalItems.append(DetailItem(title: "MIME TYPE", value: mimeType))
            }
            
            if model.isEncrypted {
                let status = model.decryptedResponseData != nil 
                    ? "🔓 Encrypted and decrypted" 
                    : "🔒 Encrypted (no key)"
                additionalItems.append(DetailItem(title: "ENCRYPTION", value: status))
            }
            
            if !additionalItems.isEmpty {
                sections.append(DetailSection(title: "ADDITIONAL INFO", items: additionalItems))
            }
            
            return sections
        }
        
        private static func detectConnectionType(headers: [String: Any]) -> String {
            // Check for text/event-stream
            if let contentType = headers["Content-Type"] as? String ?? headers["content-type"] as? String {
                if contentType.contains("text/event-stream") {
                    return "Server-Sent Events (SSE)"
                }
            }
            return ""
        }
        
        private static func isServerSentEvent(model: HttpModel) -> Bool {
            guard let headers = model.responseHeaderFields else { return false }
            if let contentType = headers["Content-Type"] as? String ?? headers["content-type"] as? String {
                return contentType.contains("text/event-stream")
            }
            return false
        }
        
        private static func countSSEEvents(data: Data?) -> Int {
            guard let data = data, let string = String(data: data, encoding: .utf8) else { return 0 }
            let lines = string.components(separatedBy: .newlines)
            return lines.filter { $0.hasPrefix("data:") }.count
        }
        
        private static func countBodyItems(data: Data?) -> Int {
            guard let data = data else { return 0 }
            
            // Try to parse as JSON
            if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                if let dictionary = jsonObject as? [String: Any] {
                    return flattenJSONCount(dictionary: dictionary)
                } else if let array = jsonObject as? [Any] {
                    return flattenJSONArrayCount(array: array)
                }
            }
            
            // Try to parse as form data
            if let string = String(data: data, encoding: .utf8) {
                let pairs = string.components(separatedBy: "&")
                let validPairs = pairs.filter { $0.contains("=") }
                if !validPairs.isEmpty {
                    return validPairs.count
                }
            }
            
            return 0
        }
        
        private static func flattenJSONCount(dictionary: [String: Any]) -> Int {
            var count = 0
            for (_, value) in dictionary {
                if let dict = value as? [String: Any] {
                    count += flattenJSONCount(dictionary: dict)
                } else if let array = value as? [Any] {
                    count += flattenJSONArrayCount(array: array)
                } else {
                    count += 1
                }
            }
            return count
        }
        
        private static func flattenJSONArrayCount(array: [Any]) -> Int {
            var count = 0
            for item in array {
                if let dict = item as? [String: Any] {
                    count += flattenJSONCount(dictionary: dict)
                } else if let nestedArray = item as? [Any] {
                    count += flattenJSONArrayCount(array: nestedArray)
                } else {
                    count += 1
                }
            }
            return count
    }
}
}

// MARK: - Actions

extension NetworkViewControllerDetail {
    @objc private func copyButtonTapped() {
        UIPasteboard.general.string = formatLog(model: model)
        showToast(message: "Copied to clipboard")
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
        showToast(message: "cURL copied to clipboard")
    }
    
    @objc private func replayButtonTapped() {
        showReplayConfirmation()
    }
    
    private func showToast(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            alert.dismiss(animated: true)
        }
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
        
        let loadingAlert = UIAlertController(title: "Sending Request...", message: nil, preferredStyle: .alert)
        present(loadingAlert, animated: true)
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let headers = model.requestHeaderFields {
            for (key, value) in headers {
                if let stringValue = value as? String {
                    request.setValue(stringValue, forHTTPHeaderField: key)
                }
            }
        }
        
        request.httpBody = model.requestData
        
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

    private func formatLog(model: HttpModel) -> String {
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
        
        if let httpResponse = response as? HTTPURLResponse {
            responseText += "HTTP/1.1 \(httpResponse.statusCode)\n"
            responseText += "Headers:\n"
            for (key, value) in httpResponse.allHeaderFields {
                responseText += "\(key): \(value)\n"
            }
            responseText += "\n"
        }
        
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

// MARK: - Table View Cells

final class DetailInfoCell: UITableViewCell {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .white
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .black
        contentView.backgroundColor = .black
        selectionStyle = .none
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            valueLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(title: String, value: String) {
        titleLabel.text = title
        valueLabel.text = value
    }
}

final class DetailNavigationCell: UITableViewCell {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let chevronImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.tintColor = .lightGray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .black
        contentView.backgroundColor = .black
        accessoryType = .none
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(badgeLabel)
        contentView.addSubview(chevronImageView)
        
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            chevronImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevronImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 12),
            
            badgeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            badgeLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -8),
            
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }
    
    func configure(title: String, badge: String?) {
        titleLabel.text = title
        badgeLabel.text = badge
        badgeLabel.isHidden = badge == nil
    }
}

// MARK: - UISearchResultsUpdating

extension NetworkViewControllerDetail: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
            filteredSections = sections
            tableView.reloadData()
            return
        }
        
        let lowercasedSearch = searchText.lowercased()
        var newFilteredSections: [DetailSection] = []
        
        for section in sections {
            let filteredItems = section.items.filter { item in
                let titleMatches = item.title.lowercased().contains(lowercasedSearch)
                let valueMatches = item.value?.lowercased().contains(lowercasedSearch) ?? false
                
                return titleMatches || valueMatches
            }
            
            if !filteredItems.isEmpty {
                newFilteredSections.append(DetailSection(title: section.title, items: filteredItems))
            }
        }
        
        filteredSections = newFilteredSections
        tableView.reloadData()
    }
}
