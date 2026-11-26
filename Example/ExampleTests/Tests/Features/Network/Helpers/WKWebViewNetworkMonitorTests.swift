//
//  WKWebViewNetworkMonitorTests.swift
//  DebugSwift
//
//  Tests deduplication of WKWebView network monitoring injection when configurations
//  share a WKUserContentController.
//

import WebKit
import XCTest
@testable import DebugSwift

@MainActor
final class WKWebViewNetworkMonitorTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DebugSwift.WKWebView.shared.enable()
        DebugSwift.WKWebView.shared.install()
    }

    func testCopiedConfigurationSharesUserContentControllerWithoutCrashing() {
        let baseConfig = WKWebViewConfiguration()
        let sharedController = baseConfig.userContentController

        let config1 = baseConfig.copy() as! WKWebViewConfiguration
        let webView1 = WKWebView(frame: .zero, configuration: config1)

        let config2 = baseConfig.copy() as! WKWebViewConfiguration
        let webView2 = WKWebView(frame: .zero, configuration: config2)

        XCTAssertNotNil(webView1)
        XCTAssertNotNil(webView2)
        XCTAssertEqual(sharedController.userScripts.count, 1)
    }

    func testExplicitlySharedUserContentControllerDoesNotDuplicateInjection() {
        let sharedController = WKUserContentController()

        let config1 = WKWebViewConfiguration()
        config1.userContentController = sharedController
        let webView1 = WKWebView(frame: .zero, configuration: config1)

        let config2 = WKWebViewConfiguration()
        config2.userContentController = sharedController
        let webView2 = WKWebView(frame: .zero, configuration: config2)

        XCTAssertNotNil(webView1)
        XCTAssertNotNil(webView2)
        XCTAssertEqual(sharedController.userScripts.count, 1)
    }

    func testDistinctConfigurationsEachReceiveNetworkMonitoringScript() {
        let config1 = WKWebViewConfiguration()
        let webView1 = WKWebView(frame: .zero, configuration: config1)

        let config2 = WKWebViewConfiguration()
        let webView2 = WKWebView(frame: .zero, configuration: config2)

        XCTAssertNotNil(webView1)
        XCTAssertNotNil(webView2)
        XCTAssertEqual(config1.userContentController.userScripts.count, 1)
        XCTAssertEqual(config2.userContentController.userScripts.count, 1)
    }
}
