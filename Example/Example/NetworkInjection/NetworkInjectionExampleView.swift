//
//  NetworkInjectionExampleView.swift
//  Example
//
//  Created by DebugSwift on 2026.
//

import SwiftUI
import DebugSwift

struct NetworkInjectionExampleView: View {
    @State private var responseText = "Tap a button to test network injection"
    @State private var isLoading = false
    @State private var delayEnabled = false
    @State private var failureEnabled = false
    @State private var rewriteEnabled = false
    @State private var rewriteURLPattern = "https://jsonplaceholder.typicode.com/todos/1"
    @State private var rewriteResponseBody = """
{
  "id": 1,
  "title": "rewritten from UI",
  "completed": true
}
"""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Network Injection Testing")
                    .font(.title)
                    .padding()
                
                // Response area
                VStack(alignment: .leading) {
                    Text("Response:")
                        .font(.headline)
                    
                    ScrollView {
                        Text(responseText)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .frame(height: 150)
                }
                .padding()
                
                if isLoading {
                    ProgressView()
                        .padding()
                }
                
                // Delay Injection Controls
                VStack(spacing: 15) {
                    Text("Delay Injection")
                        .font(.headline)
                    
                    Toggle("Enable Delay", isOn: $delayEnabled)
                        .onChange(of: delayEnabled) { newValue in
                            if newValue {
                                DebugSwift.Network.shared.enableRequestDelay(2.0)
                            } else {
                                DebugSwift.Network.shared.disableRequestDelay()
                            }
                        }
                    
                    Button("Test with Fixed 3s Delay") {
                        DebugSwift.Network.shared.enableRequestDelay(3.0)
                        Task { await makeRequest() }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Button("Test with Random Delay (1-5s)") {
                        DebugSwift.Network.shared.enableRequestDelay(min: 1.0, max: 5.0)
                        Task { await makeRequest() }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                
                // Failure Injection Controls
                VStack(spacing: 15) {
                    Text("Failure Injection")
                        .font(.headline)
                    
                    Toggle("Enable Failure (50%)", isOn: $failureEnabled)
                        .onChange(of: failureEnabled) { newValue in
                            if newValue {
                                DebugSwift.Network.shared.enableFailureInjection(
                                    failureRate: 0.5,
                                    failureType: .timeout
                                )
                            } else {
                                DebugSwift.Network.shared.disableFailureInjection()
                            }
                        }
                    
                    Button("Test Timeout Error") {
                        DebugSwift.Network.shared.enableFailureInjection(
                            failureRate: 1.0,
                            failureType: .timeout
                        )
                        Task { await makeRequest() }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Button("Test Connection Lost") {
                        DebugSwift.Network.shared.enableFailureInjection(
                            failureRate: 1.0,
                            failureType: .connectionLost
                        )
                        Task { await makeRequest() }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Button("Test HTTP 404 Error") {
                        DebugSwift.Network.shared.enableHTTPErrorInjection(
                            failureRate: 1.0,
                            statusCodes: [404]
                        )
                        Task { await makeRequest() }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Button("Test HTTP 500 Error") {
                        DebugSwift.Network.shared.enableHTTPErrorInjection(
                            failureRate: 1.0,
                            statusCodes: [500]
                        )
                        Task { await makeRequest() }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Button("Test Random HTTP Errors") {
                        DebugSwift.Network.shared.enableHTTPErrorInjection(
                            failureRate: 1.0,
                            statusCodes: [400, 401, 403, 404, 500, 502, 503]
                        )
                        Task { await makeRequest() }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
                
                // Response Rewrite Injection Controls
                VStack(spacing: 15) {
                    Text("Response Body Rewrite")
                        .font(.headline)
                    
                    Text("Configure a custom rewrite rule")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Toggle("Enable Rewrite", isOn: $rewriteEnabled)
                        .onChange(of: rewriteEnabled) { newValue in
                            if newValue {
                                applyRewriteRule()
                            } else {
                                DebugSwift.Network.shared.disableResponseBodyRewrite()
                            }
                        }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("URL Wildcard Pattern")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("https://api.example.com/path/*", text: $rewriteURLPattern)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled(true)
                            .autocapitalization(.none)
                            .onChange(of: rewriteURLPattern) { _ in
                                if rewriteEnabled {
                                    applyRewriteRule()
                                }
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Response Body")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextEditor(text: $rewriteResponseBody)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 120)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .onChange(of: rewriteResponseBody) { _ in
                                if rewriteEnabled {
                                    applyRewriteRule()
                                }
                            }
                    }
                    
                    Button("Test Request With Current Rule") {
                        Task { await makeRequest() }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.purple.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(10)
                
                // Combined Test
                VStack(spacing: 15) {
                    Text("Combined Test")
                        .font(.headline)
                    
                    Button("Test Delay + Failure") {
                        DebugSwift.Network.shared.enableRequestDelay(2.0)
                        DebugSwift.Network.shared.enableFailureInjection(
                            failureRate: 1.0,
                            failureType: .timeout
                        )
                        Task { await makeRequest() }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
                
                // Normal Request
                Button("Make Normal Request") {
                    DebugSwift.Network.shared.disableRequestDelay()
                    DebugSwift.Network.shared.disableFailureInjection()
                    DebugSwift.Network.shared.disableResponseBodyRewrite()
                    rewriteEnabled = false
                    Task { await makeRequest() }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding()
            }
            .padding()
        }
    }
    
    @MainActor
    private func makeRequest() async {
        isLoading = true
        responseText = "Making request..."
        
        let startTime = Date()
        
        do {
            let url = URL(string: "https://jsonplaceholder.typicode.com/todos/1")!
            let (data, response) = try await URLSession.shared.data(from: url)
            
            let duration = Date().timeIntervalSince(startTime)
            
            if let httpResponse = response as? HTTPURLResponse {
                let jsonString = String(data: data, encoding: .utf8) ?? "Unable to decode"
                responseText = """
                ✅ Success
                Duration: \(String(format: "%.2f", duration))s
                Status: \(httpResponse.statusCode)
                
                Response:
                \(jsonString)
                """
            }
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            responseText = """
            ❌ Error
            Duration: \(String(format: "%.2f", duration))s
            
            Error: \(error.localizedDescription)
            """
        }
        
        isLoading = false
    }
    
    private func applyRewriteRule() {
        let trimmedPattern = rewriteURLPattern.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPattern.isEmpty else { return }
        
        DebugSwift.Network.shared.enableResponseBodyRewrite(
            rules: [
                ResponseBodyRewriteRule(
                    urlPattern: trimmedPattern,
                    responseBody: rewriteResponseBody
                )
            ]
        )
    }
}

#Preview {
    NetworkInjectionExampleView()
}
