//
//  RequestManager.swift
//  Example
//
//  Created by Matheus Gois on 19/12/23.
//

import Foundation

enum RequestManager {
    static func mockRequest(url: String) {
        let url = URL(string: url)!

        let session = URLSession.shared

        let task = session.dataTask(with: url) { data, _, error in
            if let error {
                print("Error: \(error)")
                return
            }

            guard let data else {
                print("No data received")
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                print("JSON Response: \(json)")
            } catch {
                print("Error parsing JSON: \(error)")
            }
        }

        task.resume()
    }
}

struct SpeedTestManager {

    enum SpeedUnit: String {
        case kbps
        case mbps
    }

    enum SpeedTestError: Error {
        case invalidURL
        case invalidResponse
        case invalidData
        case downloadError
    }

    typealias SpeedTestCompletion = (Result<SpeedInfo, SpeedTestError>) -> Void

    func testSpeed(completion: @escaping SpeedTestCompletion) {
        guard let url = URL(string: "https://www.apple.com") else {
            completion(.failure(.invalidURL))
            return
        }

        let startTime = CFAbsoluteTimeGetCurrent()

        URLSession.shared.dataTask(with: url) { (_, response, error) in
            guard error == nil, let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.downloadError))
                return
            }

            guard httpResponse.statusCode == 200 else {
                completion(.failure(.invalidResponse))
                return
            }

            let endTime = CFAbsoluteTimeGetCurrent()
            let elapsedTime = endTime - startTime
            let speedInKbps = Double(httpResponse.expectedContentLength) / elapsedTime / 1024.0

            let speedResult = determineSpeedUnit(speedInKbps)

            completion(.success(speedResult))
        }.resume()
    }

    private func determineSpeedUnit(_ speedInKbps: Double) -> SpeedInfo {
        if speedInKbps < 1000 {
            return .init(speed: speedInKbps, unit: .kbps)
        } else {
            let speedInMbps = speedInKbps / 1000.0
            return .init(speed: speedInMbps, unit: .mbps)
        }
    }
}

extension SpeedTestManager {
    struct SpeedInfo {
        var speed: Double
        var unit: SpeedUnit

        func formattedString() -> String {
            let formattedSpeed = speed.formattedStringWithDecimal(3)
            return "Velocidade: \(formattedSpeed) \(unit.rawValue)"
        }
    }
}

fileprivate extension Double {
    func formattedStringWithDecimal(_ decimalPlaces: Int) -> String {
        return String(format: "%.\(decimalPlaces)f", self)
    }
}
