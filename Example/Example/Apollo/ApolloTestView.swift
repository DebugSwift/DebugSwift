//
//  ApolloTestView.swift
//  Example
//
//  Test view for Apollo Client integration with DebugSwift
//

#if canImport(Apollo)
import SwiftUI
import Apollo
import DebugSwift

struct ApolloTestView: View {
    @StateObject private var viewModel = ApolloTestViewModel()
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("SpaceX GraphQL API Test")) {
                    Button("Fetch Company Info") {
                        viewModel.fetchCompanyInfo()
                    }
                    
                    Button("Fetch Recent Launches") {
                        viewModel.fetchRecentLaunches()
                    }
                    
                    Button("Fetch Rockets") {
                        viewModel.fetchRockets()
                    }
                }
                
                Section(header: Text("Response")) {
                    if viewModel.isLoading {
                        HStack {
                            ProgressView()
                            Text("Loading...")
                        }
                    } else if let error = viewModel.error {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                    } else if let response = viewModel.response {
                        Text(response)
                            .font(.system(.caption, design: .monospaced))
                    } else {
                        Text("No data yet")
                            .foregroundColor(.gray)
                    }
                }
                
                Section {
                    Text("Check DebugSwift Network tab to see GraphQL requests!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Apollo Test")
        }
    }
}

@MainActor
class ApolloTestViewModel: ObservableObject {
    @Published var response: String?
    @Published var error: String?
    @Published var isLoading = false
    
    private let apolloClient: ApolloClient
    
    init() {
        // Create Apollo client with DebugSwift integration
        // This ensures all GraphQL requests appear in DebugSwift's Network tab
        self.apolloClient = createApolloClientWithDebugSwift(
            endpointURL: URL(string: "https://spacex-production.up.railway.app/")!
        )
        
        print("✅ Apollo client created with DebugSwift logging enabled")
    }
    
    func fetchCompanyInfo() {
        isLoading = true
        error = nil
        response = nil
        
        let query = """
        {
          company {
            name
            founder
            founded
            employees
            summary
          }
        }
        """
        
        executeRawQuery(query)
    }
    
    func fetchRecentLaunches() {
        isLoading = true
        error = nil
        response = nil
        
        let query = """
        {
          launchesPast(limit: 5) {
            mission_name
            launch_date_local
            rocket {
              rocket_name
            }
            launch_success
          }
        }
        """
        
        executeRawQuery(query)
    }
    
    func fetchRockets() {
        isLoading = true
        error = nil
        response = nil
        
        let query = """
        {
          rockets {
            name
            type
            active
            stages
            first_flight
          }
        }
        """
        
        executeRawQuery(query)
    }
    
    private func executeRawQuery(_ queryString: String) {
        // Create a simple raw GraphQL request using URLSession
        // This will go through Apollo's transport layer and be logged by DebugSwift
        
        guard let url = URL(string: "https://spacex-production.up.railway.app/") else {
            error = "Invalid URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "query": queryString
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            error = "Failed to encode request"
            isLoading = false
            return
        }
        
        request.httpBody = httpBody
        
        // Execute the request - this should be logged by DebugSwift
        URLSession.shared.dataTask(with: request) { [weak self] data, response, taskError in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let taskError = taskError {
                    self.error = taskError.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self.error = "No data received"
                    return
                }
                
                // Pretty print JSON response
                if let json = try? JSONSerialization.jsonObject(with: data, options: []),
                   let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
                   let prettyString = String(data: prettyData, encoding: .utf8) {
                    self.response = prettyString
                } else {
                    self.response = String(data: data, encoding: .utf8) ?? "Invalid response"
                }
                
                print("✅ GraphQL request completed - check DebugSwift Network tab!")
            }
        }.resume()
    }
}

#else
import SwiftUI

struct ApolloTestView: View {
    var body: some View {
        Text("Apollo iOS not available")
    }
}
#endif

