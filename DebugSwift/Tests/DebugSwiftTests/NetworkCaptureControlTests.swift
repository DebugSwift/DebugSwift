import Foundation
import Testing
@testable import DebugSwift

@Suite("Network capture control")
struct NetworkCaptureControlTests {
    @Test("capture can be disabled and re-enabled")
    @MainActor
    func togglesCapture() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        DebugSwift.Network.shared.injectIntoConfiguration(configuration)
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        DebugSwift.Network.shared.setCaptureEnabled(false)
        let disabledResponse = try await session.data(for: URLRequest(url: URL(string: "https://example.com/capture-control-disabled")!))
        #expect(disabledResponse.0 as? HTTPURLResponse != nil)

        DebugSwift.Network.shared.setCaptureEnabled(true)
        let enabledResponse = try await session.data(for: URLRequest(url: URL(string: "https://example.com/capture-control-enabled")!))
        #expect(enabledResponse.0 as? HTTPURLResponse != nil)

        DebugSwift.Network.shared.setCaptureEnabled(false)
    }
}
