//
//  HyperionSwiftDemoView.swift
//  Example
//
//  Created by Matheus Gois on 02/01/25.
//

import SwiftUI
import UIKit
import DebugSwift

struct HyperionSwiftDemoView: View {
    @State private var showInstructions = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Instructions banner
                if showInstructions {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("HyperionSwift Measurement Tool")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Button("✕") {
                                showInstructions = false
                            }
                            .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How to enable:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text("• Go to DebugSwift → Interface tab → Toggle 'UI measurements'")
                                .foregroundColor(.secondary)
                            Text("• Or long press the DebugSwift floating ball (0.8s)")
                                .foregroundColor(.secondary)
                            
                            Text("How to use:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.top, 8)
                            
                            Text("1. Tap any UI element to select it (blue border)")
                            Text("2. Tap another element to compare (dashed border)")  
                            Text("3. See exact distances in points between elements")
                            Text("4. Guide lines show element alignment")
                            Text("5. Tap selected element again to deselect")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Header
                VStack(spacing: 8) {
                    Text("📏 UI Measurement Demo")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Interactive layouts for testing HyperionSwift")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Card Layout Demo
                VStack(spacing: 16) {
                    Text("Card Layout")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 12) {
                        // Card 1
                        VStack {
                            Image(systemName: "heart.fill")
                                .font(.largeTitle)
                                .foregroundColor(.red)
                            Text("Favorites")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(width: 80, height: 80)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Card 2  
                        VStack {
                            Image(systemName: "star.fill")
                                .font(.largeTitle)
                                .foregroundColor(.yellow)
                            Text("Starred")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(width: 80, height: 80)
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Card 3
                        VStack {
                            Image(systemName: "bookmark.fill")
                                .font(.largeTitle)
                                .foregroundColor(.blue)
                            Text("Saved")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(width: 80, height: 80)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Button Stack Demo
                VStack(spacing: 12) {
                    Text("Button Spacing")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 8) {
                        Button(action: {}) {
                            Text("Primary Action")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        
                        Button(action: {}) {
                            Text("Secondary Action")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                        }
                        
                        Button(action: {}) {
                            Text("Tertiary Action")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // List Items Demo
                VStack(spacing: 12) {
                    Text("List Item Spacing")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 0) {
                        ForEach(0..<4) { index in
                            HStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text("\(index + 1)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("List Item \(index + 1)")
                                        .font(.headline)
                                    Text("Subtitle text here")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            
                            if index < 3 {
                                Divider()
                                    .padding(.leading, 56)
                            }
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Floating Action Button Demo
                ZStack {
                    VStack(spacing: 12) {
                        Text("Floating Elements")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Measure distances between overlapping elements")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 120)
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(16)
                    
                    // Floating button
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {}) {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            }
                            .offset(x: -8, y: -8)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Complex Layout Demo
                VStack(spacing: 16) {
                    Text("Complex Layout")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        // Header
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Product Title")
                                    .font(.headline)
                                Text("$99.99")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Image(systemName: "heart")
                                    .font(.title3)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Image placeholder
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 150)
                            .cornerRadius(8)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                        
                        // Tags
                        HStack {
                            ForEach(["New", "Sale", "Popular"], id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                            Spacer()
                        }
                        
                        // Action buttons
                        HStack(spacing: 12) {
                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "cart")
                                    Text("Add to Cart")
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                            }
                            
                            Button(action: {}) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.blue, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Bottom spacing
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 50)
            }
        }
        .navigationTitle("HyperionSwift Demo")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}

struct HyperionSwiftDemoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HyperionSwiftDemoView()
        }
    }
} 
