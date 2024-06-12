//
//  ContentView.swift
//  Example_SwiftUI
//
//  Created by Matheus Gois on 16/12/23.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @State private var userTrackingMode: MKUserTrackingMode = .follow

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

                NavigationLink(
                    destination: FileUploadView()
                ) {
                    Text("Alamofire Upload")
                }

                NavigationLink(
                    destination: MapView(userTrackingMode: $userTrackingMode)
                        .edgesIgnoringSafeArea(.all)
                ) {
                    Text("Map View")
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
