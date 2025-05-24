//
//  MockRequest.swift
//  Example
//
//  Created by Matheus Gois on 12/06/24.
//

import SwiftUI

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
