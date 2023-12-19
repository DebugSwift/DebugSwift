//
//  ErrorHelper.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

enum ErrorHelper {
    static func handle(_ error: Error?, model: HttpModel) -> HttpModel {
        if error == nil {
            // https://httpstatuses.com
            switch Int(model.statusCode ?? "") {
            case 100:
                model.errorDescription = "error-continue-description".localized()
                model.errorLocalizedDescription = "error-continue".localized()
            case 101:
                model.errorDescription = "error-switching-protocols-description".localized()
                model.errorLocalizedDescription = "error-switching-protocols".localized()
            case 102:
                model.errorDescription = "error-processing-description".localized()
                model.errorLocalizedDescription = "error-processing".localized()
            case 103:
                model.errorDescription = "error-checkpoint-description".localized()
                model.errorLocalizedDescription = "error-checkpoint".localized()
            case 122:
                model.errorDescription = "error-uri-too-long-description".localized()
                model.errorLocalizedDescription = "error-uri-too-long".localized()
            case 300:
                model.errorDescription = "error-multiple-choices-description".localized()
                model.errorLocalizedDescription = "error-multiple-choices".localized()
            case 301:
                model.errorDescription = "error-moved-permanently-description".localized()
                model.errorLocalizedDescription = "error-moved-permanently".localized()
            case 302:
                model.errorDescription = "error-found-description".localized()
                model.errorLocalizedDescription = "error-found".localized()
            case 303:
                model.errorDescription = "error-see-other-description".localized()
                model.errorLocalizedDescription = "error-see-other".localized()
            case 304:
                model.errorDescription = "error-not-modified-description".localized()
                model.errorLocalizedDescription = "error-not-modified".localized()
            case 305:
                model.errorDescription = "error-use-proxy-description".localized()
                model.errorLocalizedDescription = "error-use-proxy".localized()
            case 306:
                model.errorDescription = "error-switch-proxy-description".localized()
                model.errorLocalizedDescription = "error-switch-proxy".localized()
            case 307:
                model.errorDescription = "error-temporary-redirect-description".localized()
                model.errorLocalizedDescription = "error-temporary-redirect".localized()
            case 308:
                model.errorDescription = "error-permanent-redirect-description".localized()
                model.errorLocalizedDescription = "error-permanent-redirect".localized()
            case 400:
                model.errorDescription = "error-bad-request-description".localized()
                model.errorLocalizedDescription = "error-bad-request".localized()
            case 401:
                model.errorDescription = "error-unauthorized-description".localized()
                model.errorLocalizedDescription = "error-unauthorized".localized()
            case 402:
                model.errorDescription = "error-payment-required-description".localized()
                model.errorLocalizedDescription = "error-payment-required".localized()
            case 403:
                model.errorDescription = "error-forbidden-description".localized()
                model.errorLocalizedDescription = "error-forbidden".localized()
            case 404:
                model.errorDescription = "error-not-found-description".localized()
                model.errorLocalizedDescription = "error-not-found".localized()
            case 405:
                model.errorDescription = "error-method-not-allowed-description".localized()
                model.errorLocalizedDescription = "error-method-not-allowed".localized()
            case 406:
                model.errorDescription = "error-not-acceptable-description".localized()
                model.errorLocalizedDescription = "error-not-acceptable".localized()
            case 407:
                model.errorDescription = "error-proxy-authentication-required-description".localized()
                model.errorLocalizedDescription = "error-proxy-authentication-required".localized()
            case 408:
                model.errorDescription = "error-request-timeout-description".localized()
                model.errorLocalizedDescription = "error-request-timeout".localized()
            case 409:
                model.errorDescription = "error-conflict-description".localized()
                model.errorLocalizedDescription = "error-conflict".localized()
            case 410:
                model.errorDescription = "error-gone-description".localized()
                model.errorLocalizedDescription = "error-gone".localized()
            case 411:
                model.errorDescription = "error-length-required-description".localized()
                model.errorLocalizedDescription = "error-length-required".localized()
            case 412:
                model.errorDescription = "error-precondition-failed-description".localized()
                model.errorLocalizedDescription = "error-precondition-failed".localized()
            case 413:
                model.errorDescription = "error-request-entity-too-large-description".localized()
                model.errorLocalizedDescription = "error-request-entity-too-large".localized()
            case 414:
                model.errorDescription = "error-request-uri-too-long-description".localized()
                model.errorLocalizedDescription = "error-request-uri-too-long".localized()
            case 415:
                model.errorDescription = "error-unsupported-media-type-description".localized()
                model.errorLocalizedDescription = "error-unsupported-media-type".localized()
            case 416:
                model.errorDescription = "error-requested-range-not-satisfiable-description".localized()
                model.errorLocalizedDescription = "error-requested-range-not-satisfiable".localized()
            case 417:
                model.errorDescription = "error-expectation-failed-description".localized()
                model.errorLocalizedDescription = "error-expectation-failed".localized()
            case 418:
                model.errorDescription = "error-im-a-teapot-description".localized()
                model.errorLocalizedDescription = "error-im-a-teapot".localized()
            case 420:
                model.errorDescription = "error-twitter-rate-limiting-description".localized()
                model.errorLocalizedDescription = "error-twitter-rate-limiting".localized()
            case 421:
                model.errorDescription = "error-misdirected-request-description".localized()
                model.errorLocalizedDescription = "error-misdirected-request".localized()
            case 422:
                model.errorDescription = "error-unprocessable-entity-description".localized()
                model.errorLocalizedDescription = "error-unprocessable-entity".localized()
            case 423:
                model.errorDescription = "error-locked-description".localized()
                model.errorLocalizedDescription = "error-locked".localized()
            case 424:
                model.errorDescription = "error-failed-dependency-description".localized()
                model.errorLocalizedDescription = "error-failed-dependency".localized()
            case 426:
                model.errorDescription = "error-upgrade-required-description".localized()
                model.errorLocalizedDescription = "error-upgrade-required".localized()
            case 428:
                model.errorDescription = "error-precondition-required-description".localized()
                model.errorLocalizedDescription = "error-precondition-required".localized()
            case 429:
                model.errorDescription = "error-too-many-requests-description".localized()
                model.errorLocalizedDescription = "error-too-many-requests".localized()
            case 431:
                model.errorDescription = "error-request-header-fields-too-large-description".localized()
                model.errorLocalizedDescription = "error-request-header-fields-too-large".localized()
            case 444:
                model.errorDescription = "error-no-response-description".localized()
                model.errorLocalizedDescription = "error-no-response".localized()
            case 449:
                model.errorDescription = "error-retry-with-description".localized()
                model.errorLocalizedDescription = "error-retry-with".localized()
            case 450:
                model.errorDescription = "error-blocked-by-windows-parental-controls-description".localized()
                model.errorLocalizedDescription = "error-blocked-by-windows-parental-controls".localized()
            case 451:
                model.errorDescription = "error-wrong-exchange-server-description".localized()
                model.errorLocalizedDescription = "error-wrong-exchange-server".localized()
            case 499:
                model.errorDescription = "error-client-closed-request-description".localized()
                model.errorLocalizedDescription = "error-client-closed-request".localized()
            case 500:
                model.errorDescription = "error-internal-server-error-description".localized()
                model.errorLocalizedDescription = "error-internal-server-error".localized()
            case 501:
                model.errorDescription = "error-not-implemented-description".localized()
                model.errorLocalizedDescription = "error-not-implemented".localized()
            case 502:
                model.errorDescription = "error-bad-gateway-description".localized()
                model.errorLocalizedDescription = "error-bad-gateway".localized()
            case 503:
                model.errorDescription = "error-service-unavailable-description".localized()
                model.errorLocalizedDescription = "error-service-unavailable".localized()
            case 504:
                model.errorDescription = "error-gateway-timeout-description".localized()
                model.errorLocalizedDescription = "error-gateway-timeout".localized()
            case 505:
                model.errorDescription = "error-http-version-not-supported-description".localized()
                model.errorLocalizedDescription = "error-http-version-not-supported".localized()
            case 506:
                model.errorDescription = "error-variant-also-negotiates-description".localized()
                model.errorLocalizedDescription = "error-variant-also-negotiates".localized()
            case 507:
                model.errorDescription = "error-insufficient-storage-description".localized()
                model.errorLocalizedDescription = "error-insufficient-storage".localized()
            case 508:
                model.errorDescription = "error-loop-detected-description".localized()
                model.errorLocalizedDescription = "error-loop-detected".localized()
            case 509:
                model.errorDescription = "error-bandwidth-limit-exceeded-description".localized()
                model.errorLocalizedDescription = "error-bandwidth-limit-exceeded".localized()
            case 510:
                model.errorDescription = "error-not-extended-description".localized()
                model.errorLocalizedDescription = "error-not-extended".localized()
            case 511:
                model.errorDescription = "error-network-authentication-required-description".localized()
                model.errorLocalizedDescription = "error-network-authentication-required".localized()
            case 526:
                model.errorDescription = "error-invalid-ssl-certificate-description".localized()
                model.errorLocalizedDescription = "error-invalid-ssl-certificate".localized()
            case 598:
                model.errorDescription = "error-network-read-timeout-description".localized()
                model.errorLocalizedDescription = "error-network-read-timeout".localized()
            case 599:
                model.errorDescription = "error-network-connect-timeout-description".localized()
                model.errorLocalizedDescription = "error-network-connect-timeout".localized()
            default:
                break
            }
        }

        return model
    }
}
