import SwiftUI
import WebKit

struct NavigationTestView: View {
    @State private var currentURL = "https://www.google.com"
    @State private var webView: WKWebView?
    
    private let testSites = [
        "https://www.google.com",
        "https://www.apple.com", 
        "https://www.github.com",
        "https://httpbin.org/json",
        "https://jsonplaceholder.typicode.com/posts/1"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // URL Bar and Navigation Buttons
            VStack(spacing: 8) {
                Text("🌐 WebView Navigation Test")
                    .font(.headline)
                    .padding(.top, 8)
                
                // Test Sites Buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(testSites, id: \.self) { site in
                            Button(action: {
                                navigateToSite(site)
                            }) {
                                VStack(spacing: 4) {
                                    Text(getSiteEmoji(for: site))
                                        .font(.title2)
                                    Text(getSiteName(for: site))
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(currentURL == site ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Current URL Display
                Text("Current: \(currentURL)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
            .background(Color(UIColor.systemGray6))
            
            // WebView
            WebViewContainer(url: currentURL) { webView in
                self.webView = webView
            }
        }
        .navigationTitle("Navigation Test")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func navigateToSite(_ url: String) {
        currentURL = url
        if let webView = webView, let urlToLoad = URL(string: url) {
            webView.load(URLRequest(url: urlToLoad))
        }
    }
    
    private func getSiteEmoji(for url: String) -> String {
        if url.contains("google") { return "🔍" }
        if url.contains("apple") { return "🍎" }
        if url.contains("github") { return "👨‍💻" }
        if url.contains("httpbin") { return "🔧" }
        if url.contains("jsonplaceholder") { return "📝" }
        return "🌐"
    }
    
    private func getSiteName(for url: String) -> String {
        if url.contains("google") { return "Google" }
        if url.contains("apple") { return "Apple" }
        if url.contains("github") { return "GitHub" }
        if url.contains("httpbin") { return "HTTPBin" }
        if url.contains("jsonplaceholder") { return "JSON API" }
        return "Website"
    }
}

struct WebViewContainer: UIViewRepresentable {
    let url: String
    let onWebViewCreated: (WKWebView) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        
        // Load initial URL
        if let initialURL = URL(string: url) {
            webView.load(URLRequest(url: initialURL))
        }
        
        // Notify parent that webView is ready
        onWebViewCreated(webView)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // URL changes are handled by the parent through direct webView reference
    }
}

#Preview {
    NavigationView {
        NavigationTestView()
    }
}
