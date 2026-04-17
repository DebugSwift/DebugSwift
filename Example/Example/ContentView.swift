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
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    @State private var userTrackingMode: MKUserTrackingMode = .follow
    @State private var presentingMap = false
    @State private var showFloatingBall = true
    @State private var showDebugger = false

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: MockRequestView()) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("REST API Demo")
                            .font(.headline)
                        Text("Test all HTTP methods with fake REST API + TLS security example")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                NavigationLink(destination: NetworkInjectionExampleView()) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Network Injection Testing")
                            .font(.headline)
                        Text("Test delay and failure injection for network requests")
                            .font(.caption)
                            .foregroundColor(.secondary)
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

                NavigationLink(destination: WebViewTestView()) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("🌐 Google WebView")
                            .font(.headline)
                        Text("Test WebKit integration with controls")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                NavigationLink(destination: DeepLinkTestView(url: URL(string: "debugswift://test?id=123"))) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("🔗 Deep Link Test View")
                            .font(.headline)
                        Text("Test deep link handling interface")
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
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        if showFloatingBall {
                            appDelegate.debugSwift.hide()
                        } else {
                            appDelegate.debugSwift.show()
                        }
                        showFloatingBall.toggle()
                    } label: {
                        Image(systemName: showFloatingBall ? "circle.fill" : "circle.dotted")
                    }

                    Button {
                        DebugSwift.debugViewControllerWillPresent()
                        showDebugger = true
                    } label: {
                        Image(systemName: "ladybug")
                    }
                    .fullScreenCover(isPresented: $showDebugger, onDismiss: {
                        DebugSwift.debugViewControllerDidDismiss()
                    }) {
                        DebugViewControllerRepresentable(onDismiss: { showDebugger = false })
                            .ignoresSafeArea()
                    }
                }
            }
        }
    }
}

struct DebugViewControllerRepresentable: UIViewControllerRepresentable {
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        let debugVC = DebugSwift.debugViewController()

        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.close)
        )
        closeButton.tintColor = .white
        debugVC.navigationItem.rightBarButtonItem = closeButton

        // Outer nav controller matches WindowManager's structure used by FloatingView
        let nav = UINavigationController(rootViewController: debugVC)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .black
        nav.navigationBar.standardAppearance = appearance
        nav.navigationBar.scrollEdgeAppearance = appearance
        nav.navigationBar.compactAppearance = appearance
        nav.overrideUserInterfaceStyle = .dark
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onDismiss: onDismiss) }

    class Coordinator: NSObject {
        let onDismiss: () -> Void
        init(onDismiss: @escaping () -> Void) { self.onDismiss = onDismiss }

        @objc func close() { onDismiss() }
    }
}
