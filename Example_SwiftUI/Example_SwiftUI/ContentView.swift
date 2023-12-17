//
//  ContentView.swift
//  Example_SwiftUI
//
//  Created by Matheus Gois on 16/12/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(
                    destination: MockRequestView(
                        endpoint: "https://reqres.in/api/users?page=\(Int.random(in: 1...5))")
                ) {
                    Text("Success Mocked Request")
                }

                NavigationLink(destination: MockRequestView(endpoint: "https://reqres.in/api/users/23")) {
                    Text("Failure Request")
                }
            }
            .navigationBarTitle("Example")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct MockRequestView: View {
    let endpoint: String
    @State private var responseText = ""

    var body: some View {
        VStack {
            Text("Endpoint: \(endpoint)")
                .font(.headline)
                .padding()

            Button("Make Mocked Request") {
                Task {
                    await mockRequest(url: URL(string: endpoint)!)
                }
            }
            .padding()

            Text(responseText)
                .padding()
        }
        .navigationBarTitle("Mocked Request")
    }

    func mockRequest(url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            responseText = "JSON Response: \(json)"
        } catch {
            responseText = "Error: \(error)"
        }
    }
}

struct MockRequestView_Previews: PreviewProvider {
    static var previews: some View {
        MockRequestView(endpoint: "https://reqres.in/api/users/1")
    }
}

#Preview {
    ContentView()
}
