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
                NavigationLink(
                    destination: MockRequestView(
                        endpoint: "https://jsonplaceholder.typicode.com/todos/\(Int.random(in: 1...5))")
                ) {
                    Text("Success Mocked Request")
                }

                NavigationLink(destination: MockRequestView(endpoint: "https://reqres.in/api/users/23")) {
                    Text("Failure Request")
                }

                NavigationLink(destination: LeakView()) {
                    Text("Memory Leak Demo")
                }

                NavigationLink(destination: ThreadCheckerTestView()) {
                    Text("ThreadChecker Test Suite")
                }

                NavigationLink(destination: WebSocketTestView()) {
                    Text("WebSocket Inspector Test")
                }

                Button("Show Map") {
                    presentingMap = true
                }
            }
            .sheet(isPresented: $presentingMap) {
                MapView()
            }
            .navigationBarTitle("Example")
        }
    }

}
