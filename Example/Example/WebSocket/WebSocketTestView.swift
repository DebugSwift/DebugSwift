//
//  WebSocketTestView.swift
//  Example
//
//  Created by DebugSwift Test on 2024.
//

import SwiftUI
import DebugSwift

@available(iOS 13.0, *)
struct WebSocketTestView: View {
    @StateObject private var webSocketManager = WebSocketTestManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("WebSocket Inspector Test")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            // Connection Status
            HStack {
                Circle()
                    .fill(webSocketManager.isConnected ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                Text(webSocketManager.connectionStatus)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            
            // Connection Controls
            HStack {
                Button(webSocketManager.isConnected ? "Disconnect" : "Connect") {
                    if webSocketManager.isConnected {
                        webSocketManager.disconnect()
                    } else {
                        webSocketManager.connect()
                    }
                }
                .foregroundColor(.blue)
                
                Spacer()
                
                Button("Clear Messages") {
                    webSocketManager.clearMessages()
                }
                .foregroundColor(.orange)
            }
            .padding(.horizontal)
            
            // Test Message Buttons
            VStack(spacing: 12) {
                Text("Send Test Messages:")
                    .font(.headline)
                
                HStack {
                    Button("Send JSON") {
                        webSocketManager.sendJSONMessage()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    Button("Send Text") {
                        webSocketManager.sendTextMessage()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                HStack {
                    Button("Send Binary") {
                        webSocketManager.sendBinaryMessage()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    Button("Ping Server") {
                        webSocketManager.sendPing()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                HStack {
                    Button("Test Commands") {
                        webSocketManager.sendTestCommands()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    
                    Button("Get Stats") {
                        webSocketManager.sendStatsCommand()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Button("Send Multiple Messages") {
                    webSocketManager.sendMultipleMessages()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(!webSocketManager.isConnected)
            
            // Messages Log
            VStack(alignment: .leading) {
                Text("Recent Messages:")
                    .font(.headline)
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(webSocketManager.messages.indices, id: \.self) { index in
                            let message = webSocketManager.messages[index]
                            HStack {
                                Text(message.direction == .sent ? "↗️" : "↙️")
                                Text(message.content)
                                    .font(.caption)
                                    .lineLimit(2)
                                Spacer()
                                Text(message.timestamp)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Instructions
            VStack(alignment: .leading, spacing: 8) {
                Text("Instructions:")
                    .font(.headline)
                Text("1. Tap 'Connect' to connect to ws.ifelse.io")
                Text("2. Send messages (they will echo back)")
                Text("3. Open DebugSwift → WebSocket tab to inspect")
                Text("4. View real-time frames and payloads")
                Text("5. Test search, filtering, and resend features")
                Text("Note: This is an echo server - it returns your messages")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
        }
        .navigationBarTitle("WebSocket Test", displayMode: .inline)
        .onDisappear {
            webSocketManager.disconnect()
        }
    }
}

@available(iOS 13.0, *)
class WebSocketTestManager: ObservableObject, @unchecked Sendable {
    @Published var isConnected = false
    @Published var connectionStatus = "Disconnected"
    @Published var messages: [TestMessage] = []
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession = URLSession(configuration: .default)
    
    // Download the server from https://gist.github.com/maatheusgois-dd/c3f3f92cd109166b5af91874103078e4
    private let serverURL = URL(string: "ws://127.0.0.1:3001/websocket")!
    
    struct TestMessage {
        let direction: Direction
        let content: String
        let timestamp: String
        
        enum Direction {
            case sent, received
        }
    }
    
    func connect() {
        guard !isConnected else { return }
        
        // Clean up any existing connection
        webSocketTask?.cancel()
        webSocketTask = nil
        
        connectionStatus = "Connecting..."
        addMessage(.received, "🔄 Connecting to \(serverURL.host!)...")
        
        // 1️⃣ Create the WebSocket task
        webSocketTask = urlSession.webSocketTask(with: serverURL)
        // 2️⃣ Resume it so the handshake actually starts
        webSocketTask?.resume()
        // 3️⃣ Only now kick off your receive loop
        startListening()
        
        // Timeout fallback
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) { [weak self] in
            if self?.isConnected == false {
                self?.handleConnectionTimeout()
            }
        }
    }
    
    private func handleConnectionTimeout() {
        connectionStatus = "Connection timeout"
        addMessage(.received, "⏰ Connection timeout - please check network")
        webSocketTask?.cancel()
        webSocketTask = nil
    }
    
    func disconnect() {
        guard isConnected || webSocketTask != nil else { return }
        
        addMessage(.sent, "🔌 Disconnecting...")
        webSocketTask?.cancel(with: .goingAway, reason: "User disconnected".data(using: .utf8))
        webSocketTask = nil
        isConnected = false
        connectionStatus = "Disconnected"
        addMessage(.received, "❌ Disconnected")
    }
    
    func sendJSONMessage() {
        let jsonMessage = """
        {
            "type": "test_message",
            "timestamp": "\(Date().timeIntervalSince1970)",
            "data": {
                "user": "iOS_Tester",
                "action": "json_test",
                "payload": "This is a JSON test message for WebSocket Inspector"
            }
        }
        """
        
        sendMessage(.string(jsonMessage))
        addMessage(.sent, "📤 JSON message sent")
    }
    
    func sendTextMessage() {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        let textMessage = "Hello WebSocket Inspector! Time: \(formatter.string(from: Date()))"
        sendMessage(.string(textMessage))
        addMessage(.sent, "📤 Text message sent")
    }
    
    func sendBinaryMessage() {
        let binaryData = "Binary test data: \(Date().timeIntervalSince1970)".data(using: .utf8) ?? Data()
        sendMessage(.data(binaryData))
        addMessage(.sent, "📤 Binary message sent (\(binaryData.count) bytes)")
    }
    
    func sendPing() {
        guard let webSocketTask = webSocketTask else { return }
        
        webSocketTask.sendPing { [weak self] error in
            Task { @MainActor [weak self] in
                if let error = error {
                    self?.addMessage(.received, "Ping failed: \(error.localizedDescription)")
                } else {
                    self?.addMessage(.sent, "Ping sent")
                }
            }
        }
        
        // 🔧 Log the ping as binary data (since ping isn't exposed in public API)
        Task { @MainActor in
            DebugSwift.WebSocket.logSentFrame(task: webSocketTask, data: Data("PING".utf8))
        }
    }
    
    func sendMultipleMessages() {
        // Send a burst of different message types
        for i in 1...5 {
            let message = "Burst message #\(i) - \(Date().timeIntervalSince1970)"
            sendMessage(.string(message))
            addMessage(.sent, "📤 Burst message #\(i)")
        }
        
        // Send additional message types with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.sendJSONMessage()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.sendBinaryMessage()
        }
    }
    
    func sendTestCommands() {
        // Send various test commands (works with local server)
        let commands = ["ping", "time", "json", "binary", "burst"]
        
        for (index, command) in commands.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.3) {
                self.sendMessage(.string(command))
                self.addMessage(.sent, "Command: \(command)")
            }
        }
    }
    
    func sendStatsCommand() {
        // Request server statistics (works with local server)
        sendMessage(.string("stats"))
        addMessage(.sent, "Command: stats")
    }
    
    func clearMessages() {
        messages.removeAll()
    }
    
    private func sendMessage(_ message: URLSessionWebSocketTask.Message) {
        guard let webSocketTask = webSocketTask, isConnected else {
            addMessage(.received, "❌ Not connected - cannot send message")
            return
        }
        
        webSocketTask.send(message) { [weak self] error in
            Task { @MainActor [weak self] in
                if let error = error {
                    self?.addMessage(.received, "❌ Failed to send: \(error.localizedDescription)")
                }
                // Success case is handled by the echo response
            }
        }
        
        // 🔧 Log the sent frame to DebugSwift WebSocket Inspector
        Task { @MainActor in
            DebugSwift.WebSocket.logSentFrame(task: webSocketTask, message: message)
        }
    }
    
    private func startListening() {
        guard let webSocketTask = webSocketTask else { return }
        
        webSocketTask.receive { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let message):
                    // First successful receive means “connected”
                    if self?.isConnected == false {
                        self?.isConnected = true
                        self?.connectionStatus = "Connected"
                        self?.addMessage(.received, "✅ WebSocket connected successfully!")
                        if let task = self?.webSocketTask {
                            DebugSwift.WebSocket.register(task: task, channelName: "WebSocket Connection")
                        }
                    }
                    
                    // Handle incoming payload…
                    switch message {
                    case .string(let text):
                        self?.addMessage(.received, "📨 \(text)")
                    case .data(let data):
                        self?.addMessage(.received, "📦 Binary: \(data.count) bytes")
                    @unknown default:
                        self?.addMessage(.received, "❓ Unknown message")
                    }
                    
                    // Continue listening
                    self?.startListening()
                    
                case .failure(let error):
                    self?.addMessage(.received, "❌ WebSocket error: \(error.localizedDescription)")
                    self?.connectionStatus = "Connection failed"
                    self?.isConnected = false
                    self?.webSocketTask = nil
                }
            }
        }
    }
    
    private func addMessage(_ direction: TestMessage.Direction, _ content: String) {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        
        let message = TestMessage(
            direction: direction,
            content: content,
            timestamp: formatter.string(from: Date())
        )
        
        messages.append(message)
        
        // Keep only last 20 messages for UI performance
        if messages.count > 20 {
            messages.removeFirst(messages.count - 20)
        }
    }
} 
