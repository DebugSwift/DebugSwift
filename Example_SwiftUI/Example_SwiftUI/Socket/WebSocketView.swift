//
//  WebSocketView.swift
//  Example_SwiftUI
//
//  Created by Matheus Gois on 22/09/24.
//

import SwiftUI
import Starscream

@available(iOS 14.0, *)
struct WebSocketView: View {
    @StateObject private var socketManager = WebSocketManager()

    var body: some View {
        VStack {
            Button(action: {
                if socketManager.isConnected {
                    socketManager.disconnect()
                } else {
                    socketManager.connect()
                }
            }) {
                Text(socketManager.isConnected ? "Disconnect WebSocket" : "Connect WebSocket")
            }
            .padding()

            Button(action: {
                socketManager.sendMessage("Hello, WebSocket!")
            }) {
                Text("Send Message")
            }
            .padding()
            .disabled(!socketManager.isConnected) // Disable if not connected

            Text("Status: \(socketManager.statusMessage)")
                .padding()
        }
        .padding()
    }
}

class WebSocketManager: ObservableObject {
    private var socket: WebSocket!
    @Published var isConnected = false
    @Published var statusMessage = "Disconnected"

    init() {
        var request = URLRequest(url: URL(string: "ws://localhost:8080")!)
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket.delegate = self
    }

    func connect() {
        socket.connect()
    }

    func disconnect() {
        socket.disconnect()
    }

    func sendMessage(_ message: String) {
        socket.write(string: message)
    }
}

extension WebSocketManager: WebSocketDelegate {
    func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        switch event {
        case .connected(let headers):
            isConnected = true
            statusMessage = "Connected: \(headers)"
            print("WebSocket connected with headers: \(headers)")
        case .disconnected(let reason, let code):
            isConnected = false
            statusMessage = "Disconnected: \(reason) with code: \(code)"
            print("WebSocket disconnected: \(reason) with code: \(code)")
        case .text(let string):
            print("Received text: \(string)")
        case .binary(let data):
            print("Received data: \(data.count) bytes")
        case .ping:
            print("Ping received")
        case .pong:
            print("Pong received")
        case .viabilityChanged:
            break
        case .reconnectSuggested:
            break
        case .cancelled:
            isConnected = false
            statusMessage = "Connection cancelled"
        case .error(let error):
            isConnected = false
            statusMessage = "Error: \(error?.localizedDescription ?? "unknown error")"
            print("WebSocket error: \(error?.localizedDescription ?? "unknown error")")
        case .peerClosed:
            print("peerClosed")
        }
    }
}
