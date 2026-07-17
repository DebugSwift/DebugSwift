//
//  GraphQLDemoView.swift
//  Example
//
//  Created by Matheus Gois (GraphQL Demo) on 17/07/26.
//

import SwiftUI

/// Fires real GraphQL POSTs against a public endpoint so the GraphQL
/// Operation Inspector is testable from the Example app.
struct GraphQLDemoView: View {
    @State private var responseText = ""
    @State private var isLoading = false
    @State private var statusCode: Int?
    @State private var errorMessage: String?

    private let endpoint = URL(string: "https://countries.trevorblades.com/")!

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("GraphQL Operation Inspector")
                    .font(.title2.bold())
                Text("Fires real GraphQL POST requests against countries.trevorblades.com. "
                    + "Open DebugSwift → Network → tap the capture to see the GraphQL section "
                    + "(operation name/type, variables, data/errors split).")
                    .foregroundColor(.secondary)

                Button(action: runQuery) {
                    Label("Run query (GetCountries)", systemImage: "play.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.accentColor.opacity(0.15))
                        .cornerRadius(8)
                }
                .disabled(isLoading)

                Button(action: runMutationShapedQuery) {
                    Label("Run mutation-shaped query", systemImage: "play.circle")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                }
                .disabled(isLoading)

                Button(action: runAnonymousQuery) {
                    Label("Run anonymous query", systemImage: "play")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                }
                .disabled(isLoading)

                if isLoading {
                    ProgressView("Sending…")
                }

                if let statusCode {
                    Text("Status: \(statusCode)")
                        .font(.subheadline)
                        .foregroundColor(statusCode == 200 ? .green : .red)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                if !responseText.isEmpty {
                    Text("Response")
                        .font(.headline)
                    Text(responseText)
                        .font(.system(.body, design: .monospaced))
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .navigationTitle("GraphQL Demo")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func runQuery() {
        let query = """
        query GetCountries($code: ID!) {
          country(code: $code) {
            name
            native
            capital
            emoji
          }
        }
        """
        let variables: [String: Any] = ["code": "BR"]
        send(query: query, variables: variables)
    }

    private func runMutationShapedQuery() {
        // A query that *looks* like a mutation in its keyword — the inspector
        // should classify it as `.mutation` based on the leading keyword.
        let query = """
        mutation SetFlag {
          __typename
        }
        """
        send(query: query, variables: nil)
    }

    private func runAnonymousQuery() {
        // No operation name — inspector should return nil for the name.
        let query = "{ __typename }"
        send(query: query, variables: nil)
    }

    private func send(query: String, variables: [String: Any]?) {
        isLoading = true
        errorMessage = nil
        responseText = ""
        statusCode = nil

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        var body: [String: Any] = ["query": query]
        if let variables { body["variables"] = variables }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error {
                    errorMessage = error.localizedDescription
                    return
                }
                if let http = response as? HTTPURLResponse {
                    statusCode = http.statusCode
                }
                if let data,
                   let json = try? JSONSerialization.jsonObject(with: data),
                   let pretty = try? JSONSerialization.data(
                       withJSONObject: json,
                       options: [.prettyPrinted, .sortedKeys]
                   ),
                   let text = String(data: pretty, encoding: .utf8) {
                    responseText = text
                } else if let data, let text = String(data: data, encoding: .utf8) {
                    responseText = text
                }
            }
        }.resume()
    }
}
