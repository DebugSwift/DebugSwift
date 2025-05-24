//
//  FileUploadView.swift
//  Example
//
//  Created by Emil Atanasov on 04/13/24.
//
// Server to test: https://github.com/ReposUniversity/file-upload-server

import SwiftUI
import Alamofire

extension Data {
    func debug() {
#if DEBUG
        let raw = String(data: self, encoding: .utf8)
        print("[Raw] \(raw ?? "empty data!")")
#endif
    }
}

struct FileUploadView: View {
    let API_BASE_URL = "http://localhost:3000"
    var body: some View {
        Button {
            Task {
                await uploadFile { progress in
                    print("Uploading.... \(progress)")
                }
            }
        } label: {
            Text("Upload")
        }
    }

    private func uploadFile(reportProgress: ((Double) -> Void)?) async {
        do {
            guard let pdfPath = Bundle.main.path(forResource: "example", ofType: "pdf") else {
                print("PDF file not found in the app bundle.")
                return
            }

            guard let pdfData = try? Data(contentsOf: URL(fileURLWithPath: pdfPath)) else {
                print("PDF data CAN'T be loaded successfully.")
                return
            }

            let params = MultipartFormData()
            let extraInfo = "This is a pdf file."
            if let data = "\(extraInfo)".data(using: .utf8) {
                params.append(data, withName: "fileInfo")
            }

            params.append(pdfData, withName: "files", fileName: "example.pdf", mimeType: "application/pdf")

            let data = try await upload(path: "/api/v1/upload", formData: params) { progress in
                reportProgress?(progress)
            }
            data.debug()
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }

    private func upload(path: String, formData: MultipartFormData, reportProgress: ((Double) -> Void)? = nil) async throws -> Data {
        let commonHeaders: HTTPHeaders = [:]

        return try await withCheckedThrowingContinuation { continuation in
            AF.upload(
                multipartFormData: formData,
                to: API_BASE_URL + path,
                headers: commonHeaders,
                requestModifier: { $0.timeoutInterval = 90 }
            )
            .uploadProgress { progress in
                DispatchQueue.main.async {
                    reportProgress?(progress.fractionCompleted)
                }
            }
            .responseData { response in
                switch response.result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: self.handleError(error: error))
                }
            }
        }
    }

    private func handleError(error: AFError) -> Error {
        if let underlyingError = error.underlyingError {
            let nsError = underlyingError as NSError
            let code = nsError.code
            if code == NSURLErrorNotConnectedToInternet
                || code == NSURLErrorTimedOut
                || code == NSURLErrorInternationalRoamingOff
                || code == NSURLErrorDataNotAllowed
                || code == NSURLErrorCannotFindHost
                || code == NSURLErrorCannotConnectToHost
                || code == NSURLErrorNetworkConnectionLost {
                var userInfo = nsError.userInfo
                userInfo[NSLocalizedDescriptionKey] = "Unable to connect to the server"
                let currentError = NSError(
                    domain: nsError.domain,
                    code: code,
                    userInfo: userInfo
                )
                return currentError
            }
        }
        return error
    }
}

#Preview {
    FileUploadView()
}
