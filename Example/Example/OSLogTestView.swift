//
//  OSLogTestView.swift
//  Example
//
//  Created by Matheus Gois on 12/05/26.
//

import SwiftUI
import OSLog

struct OSLogTestView: View {
    @State private var logCount = 0
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example", category: "TestCategory")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("OSLog Console Test")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                Text("Test the OSLog capture functionality by generating various log messages. Open OSLog Console in the App tab to see them.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Divider()
                    .padding(.vertical)
                
                VStack(spacing: 12) {
                    Button(action: logInfo) {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("Log Info Message")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: logDebug) {
                        HStack {
                            Image(systemName: "ladybug")
                            Text("Log Debug Message")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: logWarning) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                            Text("Log Warning Message")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: logError) {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Log Error Message")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: logMultiple) {
                        HStack {
                            Image(systemName: "arrow.3.trianglepath")
                            Text("Log 10 Messages")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: logDifferentSubsystems) {
                        HStack {
                            Image(systemName: "square.grid.3x3")
                            Text("Log Different Subsystems")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.4, green: 0.2, blue: 0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.vertical)
                
                VStack(spacing: 8) {
                    Text("Total logs generated: \(logCount)")
                        .font(.headline)
                    
                    Button("Reset Counter") {
                        logCount = 0
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("OSLog Test")
    }
    
    private func logInfo() {
        logger.info("[OSLogTest] This is an info message #\(self.logCount)")
        logCount += 1
    }
    
    private func logDebug() {
        logger.debug("[OSLogTest] This is a debug message #\(self.logCount)")
        logCount += 1
    }
    
    private func logWarning() {
        logger.warning("[OSLogTest] This is a warning message #\(self.logCount)")
        logCount += 1
    }
    
    private func logError() {
        logger.error("[OSLogTest] This is an error message #\(self.logCount)")
        logCount += 1
    }
    
    private func logMultiple() {
        for i in 0..<10 {
            logger.info("[OSLogTest] Bulk message \(i + 1)/10 - Count #\(self.logCount + i)")
        }
        logCount += 10
    }
    
    private func logDifferentSubsystems() {
        let logger1 = Logger(subsystem: "com.example.network", category: "API")
        logger1.info("[Network] API request started")
        
        let logger2 = Logger(subsystem: "com.example.database", category: "CoreData")
        logger2.info("[Database] Fetching records")
        
        let logger3 = Logger(subsystem: "com.example.ui", category: "ViewLifecycle")
        logger3.info("[UI] View appeared")
        
        logger.info("[OSLogTest] Logged to 3 different subsystems")
        
        logCount += 4
    }
}

#Preview {
    NavigationView {
        OSLogTestView()
    }
}
