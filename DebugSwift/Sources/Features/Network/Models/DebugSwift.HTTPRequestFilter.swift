// 
//  HTTPRequestFilter.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import Foundation

struct HTTPRequestFilter {
    var methods: Set<String> = []
    var statusCodeRanges: [StatusCodeRange] = []
    var contentTypes: Set<String> = []
    var minResponseTime: Double?
    var maxResponseTime: Double?
    var minSize: Int?
    var maxSize: Int?
    var showOnlyErrors: Bool = false
    var showOnlySuccessful: Bool = false
    var hostFilters: Set<String> = []
    var timeRange: TimeRange?
    
    var isActive: Bool {
        return !methods.isEmpty ||
               !statusCodeRanges.isEmpty ||
               !contentTypes.isEmpty ||
               minResponseTime != nil ||
               maxResponseTime != nil ||
               minSize != nil ||
               maxSize != nil ||
               showOnlyErrors ||
               showOnlySuccessful ||
               !hostFilters.isEmpty ||
               timeRange != nil
    }
    
    func matches(_ request: HttpModel) -> Bool {
        // Method filter
        if !methods.isEmpty {
            guard let method = request.method, methods.contains(method) else {
                return false
            }
        }
        
        // Status code filter
        if !statusCodeRanges.isEmpty {
            guard let statusCode = request.statusCode,
                  let code = Int(statusCode),
                  statusCodeRanges.contains(where: { $0.contains(code) }) else {
                return false
            }
        }
        
        // Content type filter
        if !contentTypes.isEmpty {
            guard let mimeType = request.mineType,
                  contentTypes.contains(where: { mimeType.lowercased().contains($0.lowercased()) }) else {
                return false
            }
        }
        
        // Response time filter
        if let minTime = minResponseTime, let maxTime = maxResponseTime {
            guard let duration = request.totalDuration,
                  let durationValue = Double(duration.replacingOccurrences(of: " (s)", with: "")),
                  durationValue >= minTime && durationValue <= maxTime else {
                return false
            }
        } else if let minTime = minResponseTime {
            guard let duration = request.totalDuration,
                  let durationValue = Double(duration.replacingOccurrences(of: " (s)", with: "")),
                  durationValue >= minTime else {
                return false
            }
        } else if let maxTime = maxResponseTime {
            guard let duration = request.totalDuration,
                  let durationValue = Double(duration.replacingOccurrences(of: " (s)", with: "")),
                  durationValue <= maxTime else {
                return false
            }
        }
        
        // Size filter
        if let minSizeBytes = minSize {
            let requestSize = request.responseData?.count ?? 0
            guard requestSize >= minSizeBytes else { return false }
        }
        
        if let maxSizeBytes = maxSize {
            let requestSize = request.responseData?.count ?? 0
            guard requestSize <= maxSizeBytes else { return false }
        }
        
        // Error/Success filter
        if showOnlyErrors && request.isSuccess {
            return false
        }
        
        if showOnlySuccessful && !request.isSuccess {
            return false
        }
        
        // Host filter
        if !hostFilters.isEmpty {
            guard let host = request.url?.host,
                  hostFilters.contains(where: { host.lowercased().contains($0.lowercased()) }) else {
                return false
            }
        }
        
        // Time range filter
        if let timeRange = timeRange {
            guard let startTime = parseTimestamp(request.startTime) else { return false }
            
            switch timeRange {
            case .lastHour:
                let oneHourAgo = Date().addingTimeInterval(-3600)
                guard startTime >= oneHourAgo else { return false }
            case .lastDay:
                let oneDayAgo = Date().addingTimeInterval(-86400)
                guard startTime >= oneDayAgo else { return false }
            case .custom(let startDate, let endDate):
                guard startTime >= startDate && startTime <= endDate else { return false }
            }
        }
        
        return true
    }
    
    private func parseTimestamp(_ timestamp: String?) -> Date? {
        guard let timestamp = timestamp else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: timestamp)
    }
}

struct StatusCodeRange {
    let min: Int
    let max: Int
    let name: String
    
    func contains(_ code: Int) -> Bool {
        return code >= min && code <= max
    }
    
    static let success = StatusCodeRange(min: 200, max: 299, name: "2xx Success")
    static let redirection = StatusCodeRange(min: 300, max: 399, name: "3xx Redirection")
    static let clientError = StatusCodeRange(min: 400, max: 499, name: "4xx Client Error")
    static let serverError = StatusCodeRange(min: 500, max: 599, name: "5xx Server Error")
    
    static let allRanges = [success, redirection, clientError, serverError]
}

enum TimeRange {
    case lastHour
    case lastDay
    case custom(start: Date, end: Date)
    
    var displayName: String {
        switch self {
        case .lastHour: return "Last Hour"
        case .lastDay: return "Last Day"
        case .custom(let start, let end):
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
    }
} 