//
//  DeadlockTestView.swift
//  Example
//
//  Created to reproduce DebugSwift console interception deadlock bug
//

import SwiftUI

struct DeadlockTestView: View {
    @State private var requestCount = 0
    @State private var isRunning = false
    @State private var statusText = "Ready to test"
    @State private var errorText = ""
    
    private let testEndpoints = [
        "https://jsonplaceholder.typicode.com/posts/1",
        "https://jsonplaceholder.typicode.com/posts/2", 
        "https://jsonplaceholder.typicode.com/users/1",
        "https://jsonplaceholder.typicode.com/users/2",
        "https://jsonplaceholder.typicode.com/albums/1",
        "https://jsonplaceholder.typicode.com/todos/1",
        "https://httpbin.org/delay/0.1",
        "https://httpbin.org/get",
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🚨 Console Deadlock Test")
                .font(.title)
                .foregroundColor(.red)
            
            Text("This test reproduces the DebugSwift deadlock bug")
                .font(.subheadline)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Status: \(statusText)")
                Text("Requests sent: \(requestCount)")
                if !errorText.isEmpty {
                    Text("⚠️ \(errorText)")
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Button(action: {
                if isRunning {
                    stopTest()
                } else {
                    startDeadlockTest()
                }
            }) {
                Text(isRunning ? "Stop Test" : "Start Deadlock Test")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isRunning ? Color.red : Color.blue)
                    .cornerRadius(8)
            }
            .disabled(false)
            
            Text("""
            ⚠️ WARNING: This test will likely freeze the UI after 25-30 requests due to DebugSwift's console interception causing a mutex deadlock in Swift's print() function.
            
            The deadlock occurs because:
            • DebugSwift redirects STDOUT using dup2()
            • Multiple concurrent print() calls create mutex contention
            • Main thread blocks waiting for stdio mutex
            
            To fix: Disable console interception in setup()
            """)
            .font(.caption)
            .padding()
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Deadlock Test")
    }
    
    private func startDeadlockTest() {
        isRunning = true
        requestCount = 0
        statusText = "Running deadlock test..."
        errorText = ""
        
        // Start multiple concurrent network requests that will trigger the deadlock
        Task {
            await runConcurrentRequests()
        }
    }
    
    private func stopTest() {
        isRunning = false
        statusText = "Test stopped"
    }
    
    private func runConcurrentRequests() async {
        // Create 50 concurrent requests to trigger the deadlock
        // Each request includes print statements that will cause mutex contention
        await withTaskGroup(of: Void.self) { group in
            for i in 1...50 {
                group.addTask {
                    await makeRequestWithPrint(requestNumber: i)
                }
                
                // Small delay to spread out the requests slightly
                try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
        }
        
        statusText = "Test completed (if UI didn't freeze)"
        isRunning = false
    }
    
    private func makeRequestWithPrint(requestNumber: Int) async {
        let endpoint = testEndpoints[requestNumber % testEndpoints.count]
        
        // Multiple print statements that will trigger console interception
        print("🚀 [Request \(requestNumber)] Starting request to \(endpoint)")
        print("🔍 [Request \(requestNumber)] Creating URL request...")
        
        do {
            guard let url = URL(string: endpoint) else {
                print("❌ [Request \(requestNumber)] Invalid URL: \(endpoint)")
                return
            }
            
            print("📡 [Request \(requestNumber)] Sending network request...")
            let request = URLRequest(url: url)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            print("📥 [Request \(requestNumber)] Received response: \(data.count) bytes")
            
            if let httpResponse = response as? HTTPURLResponse {
                print("✅ [Request \(requestNumber)] Status: \(httpResponse.statusCode)")
            }
            
            // Update UI on main thread
            await MainActor.run {
                requestCount += 1
                print("📊 [Request \(requestNumber)] Total completed: \(requestCount)")
            }
            
        } catch {
            print("❌ [Request \(requestNumber)] Error: \(error.localizedDescription)")
            await MainActor.run {
                errorText = "Request \(requestNumber) failed: \(error.localizedDescription)"
            }
        }
        
        print("🏁 [Request \(requestNumber)] Request completed")
    }
}

#Preview {
    NavigationView {
        DeadlockTestView()
    }
} 