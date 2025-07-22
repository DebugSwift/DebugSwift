//
//  ContentView.swift
//  Example
//
//  Created by Matheus Gois on 16/12/23.
//

import SwiftUI
import MapKit
import DebugSwift

struct ContentView: View {

    @State private var userTrackingMode: MKUserTrackingMode = .follow
    @State private var presentingMap = false

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: MockRequestView()) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("JSONPlaceholder API Demo")
                            .font(.headline)
                        Text("Test all HTTP methods with fake REST API")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                NavigationLink(destination: DeadlockTestView()) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("🚨 Console Deadlock Test")
                            .font(.headline)
                        Text("Reproduce DebugSwift console interception deadlock")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.vertical, 4)
                }

                NavigationLink(destination: LeakView()) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Memory Leak Demo")
                            .font(.headline)
                        Text("Test memory leak detection")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                NavigationLink(destination: ThreadCheckerTestView()) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ThreadChecker Test Suite")
                            .font(.headline)
                        Text("Test thread safety violations")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                NavigationLink(destination: WebSocketTestView()) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("WebSocket Inspector Test")
                            .font(.headline)
                        Text("Test WebSocket connections")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                NavigationLink(destination: HyperionSwiftDemoView()) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("📏 HyperionSwift Measurement Tool")
                            .font(.headline)
                        Text("Interactive UI element measurement and spacing tool")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Button("Show Map") {
                    presentingMap = true
                }
                .padding(.vertical, 4)
            }
            .sheet(isPresented: $presentingMap) {
                MapView()
            }
            .navigationBarTitle("DebugSwift Examples")
        }
    }

}
