//
//  WebViewTestView.swift
//  Example
//
//  Created by Matheus Gois.
//

import SwiftUI
import WebKit

struct WebViewTestView: View {
    @State private var isLoading = true
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var currentURL = "https://www.google.com"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // URL Bar
                HStack {
                    HStack {
                        Image(systemName: "lock.shield")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text(currentURL)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        Spacer()
                        
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Button(action: {
                                // Refresh action will be handled by WebView
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Navigation Controls
                HStack(spacing: 20) {
                    Button(action: {
                        // Go back action will be handled by WebView
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(canGoBack ? .blue : .gray)
                    }
                    .disabled(!canGoBack)
                    
                    Button(action: {
                        // Go forward action will be handled by WebView
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(canGoForward ? .blue : .gray)
                    }
                    .disabled(!canGoForward)
                    
                    Spacer()
                    
                    Button(action: {
                        // Share action
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color(.separator)),
                    alignment: .bottom
                )
                
                // WebView
                GoogleWebView(
                    isLoading: $isLoading,
                    canGoBack: $canGoBack,
                    canGoForward: $canGoForward,
                    currentURL: $currentURL
                )
                .edgesIgnoringSafeArea(.bottom)
            }
        }
        .navigationBarTitle("Google WebView", displayMode: .inline)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GoogleWebView: UIViewRepresentable {
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var currentURL: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        
        // Load Google
        if let url = URL(string: "https://www.google.com") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Update navigation state
        DispatchQueue.main.async {
            self.canGoBack = webView.canGoBack
            self.canGoForward = webView.canGoForward
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: GoogleWebView
        
        init(_ parent: GoogleWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.canGoBack = webView.canGoBack
                self.parent.canGoForward = webView.canGoForward
                self.parent.currentURL = webView.url?.absoluteString ?? ""
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
            print("WebView navigation failed: \(error.localizedDescription)")
        }
    }
}

#Preview {
    WebViewTestView()
}
