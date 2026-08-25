//
//  DeepLinkTestView.swift
//  Example
//
//  Created by DebugSwift on 13/02/26.
//

import SwiftUI

struct DeepLinkTestView: View {
    let url: URL?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.green)
                
                Text("Deep Link Opened!")
                    .font(.title)
                    .fontWeight(.bold)
                
                if let url = url {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("URL Details:")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        DetailRow(label: "Scheme:", value: url.scheme ?? "N/A")
                        DetailRow(label: "Host:", value: url.host ?? "N/A")
                        DetailRow(label: "Path:", value: url.path.isEmpty ? "/" : url.path)
                        
                        if let query = url.query, !query.isEmpty {
                            DetailRow(label: "Query:", value: query)
                        }
                        
                        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                           let queryItems = components.queryItems, !queryItems.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Parameters:")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                ForEach(queryItems, id: \.name) { item in
                                    HStack {
                                        Text(item.name)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(item.value ?? "")
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.horizontal, 8)
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(20)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else {
                    Text("No URL information available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Close")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .padding(.top, 40)
            .navigationBarTitle("Deep Link Test", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}

struct DeepLinkTestView_Previews: PreviewProvider {
    static var previews: some View {
        DeepLinkTestView(url: URL(string: "debugswift://test?id=123&name=example"))
    }
}
