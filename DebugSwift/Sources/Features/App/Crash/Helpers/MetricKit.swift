//
//  MetricKit.swift
//  DebugSwift
//
//  Created by Matheus Gois on 27/04/24.
//

import Foundation
import MetricKit

@available(iOS 13.0, *)
class MetricKitReporter: NSObject {
    private let fileName = "metrics"

    static let shared = MetricKitReporter()

    override init() {
        super.init()
    }

    func register() {
        MXMetricManager.shared.add(self)
    }

    private func submitData(_ data: Data) {
        saveMetricToFile(value: data)
    }

    private func saveMetricToFile(value: Data) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Unable to access documents directory")
            return
        }
        let fileURL = documentsDirectory.appendingPathComponent(fileName).appendingPathExtension("txt")
        do {
            try "\(value)".write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Error saving metric to file:", error)
        }
    }

    func loadMetricFromFile() -> Data? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Unable to access documents directory")
            return nil
        }
        let fileURL = documentsDirectory.appendingPathComponent(fileName).appendingPathExtension("txt")
        do {
            return try Data(contentsOf: fileURL)
        } catch {
            print("Error loading metric from file:", error)
            return nil
        }
    }
}

@available(iOS 13.0, *)
extension MetricKitReporter: MXMetricManagerSubscriber {
    func didReceive(_ payloads: [MXMetricPayload]) {
        print(payloads)
    }

    @available(iOS 14.0, *)
    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        payloads.map({ $0.jsonRepresentation() }).forEach({ submitData($0) })
    }
}
