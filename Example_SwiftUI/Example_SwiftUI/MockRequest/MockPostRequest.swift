//
//  MockPostRequest.swift
//  Example_SwiftUI
//
//  Created by Matheus Gois on 27/12/24.
//

import SwiftUI
import Alamofire
import Foundation

struct UserRequest: Encodable {
    let name: String
    let job: String
}

struct UserResponse: Decodable {
    let name: String
    let job: String
    let id: String
    let createdAt: String
}

struct MockPostRequestView: View {
    let endpoint: String
    @State private var responseText = ""

    var body: some View {
        VStack {
            Text("Endpoint: \(endpoint)")
                .font(.headline)
                .padding()

            Button("Make Mocked Request") {
                Task {
                    await makePostRequest()
                }
            }
            .padding()

            Text(responseText)
                .padding()
        }
        .navigationBarTitle("Mocked Request")
    }

    func makePostRequest() async {
        guard let url = URL(string: endpoint) else {
            responseText = "Invalid URL"
            return
        }

        let user = UserRequest(name: "morpheus", job: "leader")

        do {
            let data = try await AF.request(
                url,
                method: .post,
                parameters: user,
                encoder: JSONParameterEncoder.default
            )
            .serializingDecodable(UserResponse.self)
            .value

            DispatchQueue.main.async {
                responseText = """
                User Created:
                Name: \(data.name)
                Job: \(data.job)
                ID: \(data.id)
                Created At: \(data.createdAt)
                """
            }
        } catch {
            DispatchQueue.main.async {
                responseText = "Error: \(error.localizedDescription)"
            }
        }
    }
}

struct MockPostRequestView_Previews: PreviewProvider {
    static var previews: some View {
        MockPostRequestView(endpoint: "https://reqres.in/api/users")
    }
}
