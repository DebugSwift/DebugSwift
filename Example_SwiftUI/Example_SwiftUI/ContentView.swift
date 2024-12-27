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
    @State private var presentingMap = false

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

                NavigationLink(destination: MockPostRequestView(endpoint: "https://reqres.in/api/users")) {
                    Text("Post Request with alamofire")
                }

                NavigationLink(
                    destination: FileUploadView()
                ) {
                    Text("Alamofire Upload")
                }

                Button("Show Map") {
                    presentingMap = true
                }

            }
            .sheet(isPresented: $presentingMap) {
                if #available(iOS 14.0, *) {
                    MapView().edgesIgnoringSafeArea(.all)
                } else {
                    MapView_13(userTrackingMode: $userTrackingMode)
                        .edgesIgnoringSafeArea(.all)
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
