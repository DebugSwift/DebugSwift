//
//  DeepLink.ViewModel.swift
//  DebugSwift
//
//  Created by DebugSwift on 13/02/26.
//

import UIKit

final class DeepLinkViewModel {
    
    // MARK: - Properties
    
    private let historyKey = "com.debugswift.deeplink.history"
    private let maxHistoryCount = 50
    
    private(set) var history: [DeepLinkEntry] = []
    
    var onHistoryUpdated: (() -> Void)?
    
    // MARK: - Initialization
    
    init() {
        loadHistory()
    }
    
    // MARK: - Public Methods
    
    func validateURL(_ urlString: String) -> (isValid: Bool, error: String?) {
        guard !urlString.trimmingCharacters(in: .whitespaces).isEmpty else {
            return (false, "URL cannot be empty")
        }
        
        guard let url = URL(string: urlString) else {
            return (false, "Invalid URL format")
        }
        
        guard url.scheme != nil else {
            return (false, "URL must have a scheme (e.g., https://, myapp://)")
        }
        
        return (true, nil)
    }
    
    func detectLinkType(_ url: URL) -> DeepLinkType {
        if url.scheme == "http" || url.scheme == "https" {
            return .universalLink
        } else {
            return .urlScheme
        }
    }
    
    @MainActor
    func openDeepLink(_ urlString: String, completion: @escaping (Bool, String?) -> Void) {
        // Validate URL
        let validation = validateURL(urlString)
        guard validation.isValid else {
            let status = DeepLinkStatus.invalid(validation.error ?? "Unknown error")
            if let url = URL(string: urlString) {
                let entry = DeepLinkEntry(url: url, type: .urlScheme, status: status)
                addToHistory(entry)
            }
            completion(false, validation.error)
            return
        }
        
        guard let url = URL(string: urlString) else {
            completion(false, "Failed to create URL")
            return
        }
        
        let type = detectLinkType(url)
        
        // Check if URL can be opened
        guard UIApplication.shared.canOpenURL(url) else {
            let status = DeepLinkStatus.failed("Cannot open URL. The app may not be configured to handle this URL scheme.")
            let entry = DeepLinkEntry(url: url, type: type, status: status)
            addToHistory(entry)
            completion(false, "Cannot open URL. The app may not be configured to handle this URL scheme.")
            return
        }
        
        // Minimize DebugSwift to floating mode before opening deep link
        WindowManager.removeDebugger()
        
        // Open the deep link after a brief delay to ensure UI is dismissed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            UIApplication.shared.open(url) { success in
                let status: DeepLinkStatus = success ? .success : .failed("Failed to open URL")
                let entry = DeepLinkEntry(url: url, type: type, status: status)
                self?.addToHistory(entry)
                
                let errorMessage = success ? nil : "Failed to open URL"
                completion(success, errorMessage)
            }
        }
    }
    
    func clearHistory() {
        history.removeAll()
        saveHistory()
        onHistoryUpdated?()
    }
    
    func deleteEntry(at index: Int) {
        guard index < history.count else { return }
        history.remove(at: index)
        saveHistory()
        onHistoryUpdated?()
    }
    
    func getQuickTestURLs() -> [String] {
        return [
            "debugswift://test",
            "debugswift://profile/123",
            "debugswift://settings",
            "https://www.apple.com",
            "https://github.com/DebugSwift/DebugSwift"
        ]
    }
    
    // MARK: - Private Methods
    
    private func addToHistory(_ entry: DeepLinkEntry) {
        history.insert(entry, at: 0)
        
        // Limit history size
        if history.count > maxHistoryCount {
            history = Array(history.prefix(maxHistoryCount))
        }
        
        saveHistory()
        onHistoryUpdated?()
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([DeepLinkEntry].self, from: data) {
            history = decoded
        }
    }
}
