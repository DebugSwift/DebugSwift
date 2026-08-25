//
//  SavedRecording.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/05/26.
//

import Foundation

struct SavedRecording: Codable, Identifiable {
    let id: UUID
    let date: Date
    let imageCount: Int
    let imageFileNames: [String]

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var title: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
}
