//
//  MockRequest.swift
//  Example
//
//  Created by Matheus Gois on 12/06/24.
//  Updated to include TLS v1.2+ security example with DebugSwift interception
//

import SwiftUI

struct APIEndpoint {
    let title: String
    let method: String
    let endpoint: String
    let body: [String: Any]?
    let description: String
    
    init(title: String, method: String, endpoint: String, body: [String: Any]? = nil, description: String) {
        self.title = title
        self.method = method
        self.endpoint = endpoint
        self.body = body
        self.description = description
    }
}

struct MockRequestView: View {
    @State private var selectedEndpoint: APIEndpoint?
    @State private var responseText = ""
    @State private var isLoading = false
    @State private var statusCode: Int?
    
    private let endpoints = [
        // GET Requests
        APIEndpoint(
            title: "Get All Posts",
            method: "GET",
            endpoint: "https://jsonplaceholder.typicode.com/posts",
            description: "Fetch all posts (100 items)"
        ),
        APIEndpoint(
            title: "Get Single Post",
            method: "GET",
            endpoint: "https://jsonplaceholder.typicode.com/posts/1",
            description: "Fetch post with ID 1"
        ),
        APIEndpoint(
            title: "Get Post Comments",
            method: "GET",
            endpoint: "https://jsonplaceholder.typicode.com/posts/1/comments",
            description: "Fetch comments for post ID 1"
        ),
        APIEndpoint(
            title: "Get Comments by Post ID",
            method: "GET",
            endpoint: "https://jsonplaceholder.typicode.com/comments?postId=1",
            description: "Fetch comments using query parameter"
        ),
        APIEndpoint(
            title: "Get All Users",
            method: "GET",
            endpoint: "https://jsonplaceholder.typicode.com/users",
            description: "Fetch all users (10 items)"
        ),
        APIEndpoint(
            title: "Get All Albums",
            method: "GET",
            endpoint: "https://jsonplaceholder.typicode.com/albums",
            description: "Fetch all albums (100 items)"
        ),
        APIEndpoint(
            title: "Get All Photos",
            method: "GET",
            endpoint: "https://jsonplaceholder.typicode.com/photos?_limit=5",
            description: "Fetch first 5 photos (limited for performance)"
        ),
        APIEndpoint(
            title: "Get All Todos",
            method: "GET",
            endpoint: "https://jsonplaceholder.typicode.com/todos?_limit=10",
            description: "Fetch first 10 todos"
        ),
        
        // POST Request
        APIEndpoint(
            title: "Create New Post",
            method: "POST",
            endpoint: "https://jsonplaceholder.typicode.com/posts",
            body: [
                "title": "My New Post",
                "body": "This is the content of my new post",
                "userId": 1
            ],
            description: "Create a new post with title and body"
        ),
        
        // PUT Request
        APIEndpoint(
            title: "Update Post (PUT)",
            method: "PUT",
            endpoint: "https://jsonplaceholder.typicode.com/posts/1",
            body: [
                "id": 1,
                "title": "Updated Post Title",
                "body": "Updated post content",
                "userId": 1
            ],
            description: "Replace entire post with new data"
        ),
        
        // PATCH Request
        APIEndpoint(
            title: "Update Post (PATCH)",
            method: "PATCH",
            endpoint: "https://jsonplaceholder.typicode.com/posts/1",
            body: [
                "title": "Partially Updated Title"
            ],
            description: "Update only specific fields of the post"
        ),
        
        // DELETE Request
        APIEndpoint(
            title: "Delete Post",
            method: "DELETE",
            endpoint: "https://jsonplaceholder.typicode.com/posts/1",
            description: "Delete post with ID 1"
        ),
        
        // Failure Request
        APIEndpoint(
            title: "User Not Found (404)",
            method: "GET",
            endpoint: "https://reqres.in/api/users/23",
            description: "Request that returns 404 error"
        ),
        
        APIEndpoint(
            title: "Invalid Endpoint (404)",
            method: "GET",
            endpoint: "https://jsonplaceholder.typicode.com/invalid-endpoint",
            description: "Test endpoint that doesn't exist"
        ),
        
        // TLS Security Example
        APIEndpoint(
            title: "TLS v1.2+ Secure Request",
            method: "GET",
            endpoint: "https://jsonplaceholder.typicode.com/posts/1",
            description: "Secure request with TLS v1.2+ (intercepted by DebugSwift)"
        )
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("JSONPlaceholder API Demo")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Test various HTTP methods with fake REST API + TLS security example")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                
                HStack(spacing: 0) {
                    // Left Panel - Endpoints List
                    VStack(alignment: .leading, spacing: 0) {
                        Text("API Endpoints")
                            .font(.headline)
                            .padding()
                        
                        ScrollView {
                            LazyVStack(spacing: 1) {
                                ForEach(endpoints.indices, id: \.self) { index in
                                    let endpoint = endpoints[index]
                                    EndpointRow(
                                        endpoint: endpoint,
                                        isSelected: selectedEndpoint?.endpoint == endpoint.endpoint && selectedEndpoint?.method == endpoint.method
                                    ) {
                                        selectedEndpoint = endpoint
                                        responseText = ""
                                        statusCode = nil
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.secondary.opacity(0.05))
                    
                    Divider()
                    
                    // Right Panel - Request/Response
                    VStack(spacing: 0) {
                        if let endpoint = selectedEndpoint {
                            RequestResponseView(
                                endpoint: endpoint,
                                responseText: $responseText,
                                isLoading: $isLoading,
                                statusCode: $statusCode
                            )
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "globe")
                                    .font(.system(size: 50))
                                    .foregroundColor(.secondary)
                                
                                Text("Select an endpoint")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                
                                Text("Choose an API endpoint from the list to test different HTTP methods")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct EndpointRow: View {
    let endpoint: APIEndpoint
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(endpoint.method)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(methodColor)
                        .cornerRadius(4)
                    
                    // Show TLS security icon for TLS example
                    if endpoint.title == "TLS v1.2+ Secure Request" {
                        HStack(spacing: 2) {
                            Image(systemName: "lock.shield.fill")
                            Text("TLS v1.2+")
                        }
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Color.green)
                        .cornerRadius(3)
                    }
                    
                    Spacer()
                }
                
                Text(endpoint.title)
                    .font(.system(.body, design: .default))
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Text(endpoint.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .overlay(
                Rectangle()
                    .frame(width: 3)
                    .foregroundColor(isSelected ? .blue : .clear),
                alignment: .leading
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var methodColor: Color {
        switch endpoint.method {
        case "GET": return .blue
        case "POST": return .green
        case "PUT": return .orange
        case "PATCH": return .purple
        case "DELETE": return .red
        default: return .gray
        }
    }
}

struct RequestResponseView: View {
    let endpoint: APIEndpoint
    @Binding var responseText: String
    @Binding var isLoading: Bool
    @Binding var statusCode: Int?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Request Details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Request Details")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Method:")
                                .fontWeight(.medium)
                            Text(endpoint.method)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(methodColor)
                                .cornerRadius(4)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Endpoint:")
                                .fontWeight(.medium)
                            Text(endpoint.endpoint)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        
                        // Show TLS security info for TLS example
                        if endpoint.title == "TLS v1.2+ Secure Request" {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Security:")
                                    .fontWeight(.medium)
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                        Text("TLS Minimum: v1.2")
                                            .font(.caption)
                                    }
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                        Text("DebugSwift Interception: Enabled")
                                            .font(.caption)
                                    }
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                        Text("Configuration Preserved: ✓")
                                            .font(.caption)
                                    }
                                }
                                .padding(6)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(4)
                            }
                        }
                        
                        if let body = endpoint.body {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Request Body:")
                                    .fontWeight(.medium)
                                Text(formatJSON(body))
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
                
                // Make Request Button
                Button(action: {
                    Task {
                        await makeRequest()
                    }
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isLoading ? "Loading..." : "Make Request")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isLoading ? Color.gray : methodColor)
                    .cornerRadius(8)
                }
                .disabled(isLoading)
                
                // Response Section
                if !responseText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Response")
                                .font(.headline)
                            
                            Spacer()
                            
                            if let statusCode = statusCode {
                                Text("Status: \(statusCode)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(statusCode < 400 ? Color.green : Color.red)
                                    .cornerRadius(4)
                            }
                        }
                        
                        ScrollView {
                            Text(responseText)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 300)
                        .padding(12)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
    }
    
    private var methodColor: Color {
        switch endpoint.method {
        case "GET": return .blue
        case "POST": return .green
        case "PUT": return .orange
        case "PATCH": return .purple
        case "DELETE": return .red
        default: return .gray
        }
    }
    
    private func makeRequest() async {
        isLoading = true
        statusCode = nil
        
        do {
            guard let url = URL(string: endpoint.endpoint) else {
                responseText = "Invalid URL"
                isLoading = false
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = endpoint.method
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Add request body for POST, PUT, PATCH
            if let body = endpoint.body, ["POST", "PUT", "PATCH"].contains(endpoint.method) {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
            }
            
            // Use TLS-secured session for TLS example
            let (data, response): (Data, URLResponse)
            if endpoint.title == "TLS v1.2+ Secure Request" {
                let tlsSession = createSecureTLSSession()
                (data, response) = try await tlsSession.data(for: request)
                responseText = "🔒 Used TLS v1.2+ secured URLSession\n\n"
            } else {
                (data, response) = try await URLSession.shared.data(for: request)
                responseText = ""
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                statusCode = httpResponse.statusCode
            }
            
            if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                responseText += formatJSON(jsonObject)
            } else {
                responseText += String(data: data, encoding: .utf8) ?? "Unable to decode response"
            }
            
        } catch {
            responseText = "Error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Creates a TLS-secured URLSession that will be properly intercepted by DebugSwift
    private func createSecureTLSSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        
        // Security configuration - now preserved by DebugSwift
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
        configuration.tlsMaximumSupportedProtocolVersion = .TLSv13
        
        // Additional security settings
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.urlCredentialStorage = nil
        configuration.httpCookieStorage = nil
        
        // Timeouts
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0
        
        print("🔒 Created TLS-secured URLSession with minimum TLSv1.2 for DebugSwift interception")
        
        return URLSession(configuration: configuration)
    }
    
    private func formatJSON(_ object: Any) -> String {
        do {
            let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted])
            return String(data: data, encoding: .utf8) ?? "Unable to format JSON"
        } catch {
            return "\(object)"
        }
    }
}
