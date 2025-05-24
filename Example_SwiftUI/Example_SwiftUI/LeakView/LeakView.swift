//
//  LeakView.swift
//  Example_SwiftUI
//
//  Created by Assistant on today's date.
//

import SwiftUI

struct LeakView: View {
    @StateObject private var leakManager = LeakManager()
    
    var body: some View {
        ZStack {
            Color.orange
                .ignoresSafeArea()
            
            Image(systemName: "drop.triangle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
                .foregroundColor(.black)
        }
        .onDisappear {
            // Create a memory leak by capturing self in a delayed closure
            leakManager.createLeak()
        }
    }
}

// Helper class to demonstrate memory leak
class LeakManager: ObservableObject {
    private var strongSelfReference: LeakManager?
    
    func createLeak() {
        // Capture self strongly in a delayed closure
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [self] in
            // This creates a retain cycle - self holds strongSelfReference
            // and the closure holds self
            self.strongSelfReference = self
            print("LeakManager instance leaked: \(self)")
        }
    }
    
    deinit {
        print("LeakManager deinitialized") // This won't be called due to the leak
    }
}

struct LeakView_Previews: PreviewProvider {
    static var previews: some View {
        LeakView()
    }
} 