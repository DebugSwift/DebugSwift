//
//  ErrorHelper.swift
//  NewCocoaDebug
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

struct ErrorHelper {
    static func handle(_ error: Error?, model: HttpModel) -> HttpModel {
        if error == nil {
            // https://httpstatuses.com
            switch Int(model.statusCode ?? "") {
            case 100:
                model.errorDescription = "Informational :\nClient should continue with request"
                model.errorLocalizedDescription = "Continue"
            case 101:
                model.errorDescription = "Informational :\nServer is switching protocols"
                model.errorLocalizedDescription = "Switching Protocols"
            case 102:
                model.errorDescription = "Informational :\nServer has received and is processing the request"
                model.errorLocalizedDescription = "Processing"
            case 103:
                model.errorDescription = "Informational :\nresume aborted PUT or POST requests"
                model.errorLocalizedDescription = "Checkpoint"
            case 122:
                model.errorDescription = "Informational :\nURI is longer than a maximum of 2083 characters"
                model.errorLocalizedDescription = "Request-URI too long"
            case 300:
                model.errorDescription = "Redirection :\nMultiple options for the resource delivered"
                model.errorLocalizedDescription = "Multiple Choices"
            case 301:
                model.errorDescription = "Redirection :\nThis and all future requests directed to the given URI"
                model.errorLocalizedDescription = "Moved Permanently"
            case 302:
                model.errorDescription = "Redirection :\nTemporary response to request found via alternative URI"
                model.errorLocalizedDescription = "Found"
            case 303:
                model.errorDescription = "Redirection :\nPermanent response to request found via alternative URI"
                model.errorLocalizedDescription = "See Other"
            case 304:
                model.errorDescription = "Redirection :\nResource has not been modified since last requested"
                model.errorLocalizedDescription = "Not Modified"
            case 305:
                model.errorDescription = "Redirection :\nContent located elsewhere, retrieve from there"
                model.errorLocalizedDescription = "Use Proxy"
            case 306:
                model.errorDescription = "Redirection :\nSubsequent requests should use the specified proxy"
                model.errorLocalizedDescription = "Switch Proxy"
            case 307:
                model.errorDescription = "Redirection :\nConnect again to different URI as provided"
                model.errorLocalizedDescription = "Temporary Redirect"
            case 308:
                model.errorDescription = "Redirection :\nConnect again to a different URI using the same method"
                model.errorLocalizedDescription = "Permanent Redirect"
            case 400:
                model.errorDescription = "Client Error :\nRequest cannot be fulfilled due to bad syntax"
                model.errorLocalizedDescription = "Bad Request"
            case 401:
                model.errorDescription = "Client Error :\nAuthentication is possible but has failed"
                model.errorLocalizedDescription = "Unauthorized"
            case 402:
                model.errorDescription = "Client Error :\nPayment required, reserved for future use"
                model.errorLocalizedDescription = "Payment Required"
            case 403:
                model.errorDescription = "Client Error :\nServer refuses to respond to request"
                model.errorLocalizedDescription = "Forbidden"
            case 404:
                model.errorDescription = "Client Error :\nRequested resource could not be found"
                model.errorLocalizedDescription = "Not Found"
            case 405:
                model.errorDescription = "Client Error :\nRequest method not supported by that resource"
                model.errorLocalizedDescription = "Method Not Allowed"
            case 406:
                model.errorDescription = "Client Error :\nContent not acceptable according to the Accept headers"
                model.errorLocalizedDescription = "Not Acceptable"
            case 407:
                model.errorDescription = "Client Error :\nClient must first authenticate itself with the proxy"
                model.errorLocalizedDescription = "Proxy Authentication Required"
            case 408:
                model.errorDescription = "Client Error :\nServer timed out waiting for the request"
                model.errorLocalizedDescription = "Request Timeout"
            case 409:
                model.errorDescription = "Client Error :\nRequest could not be processed because of conflict"
                model.errorLocalizedDescription = "Conflict"
            case 410:
                model.errorDescription = "Client Error :\nResource is no longer available and will not be available again"
                model.errorLocalizedDescription = "Gone"
            case 411:
                model.errorDescription = "Client Error :\nRequest did not specify the length of its content"
                model.errorLocalizedDescription = "Length Required"
            case 412:
                model.errorDescription = "Client Error :\nServer does not meet request preconditions"
                model.errorLocalizedDescription = "Precondition Failed"
            case 413:
                model.errorDescription = "Client Error :\nRequest is larger than the server is willing or able to process"
                model.errorLocalizedDescription = "Request Entity Too Large"
            case 414:
                model.errorDescription = "Client Error :\nURI provided was too long for the server to process"
                model.errorLocalizedDescription = "Request-URI Too Long"
            case 415:
                model.errorDescription = "Client Error :\nServer does not support media type"
                model.errorLocalizedDescription = "Unsupported Media Type"
            case 416:
                model.errorDescription = "Client Error :\nClient has asked for an unprovidable portion of the file"
                model.errorLocalizedDescription = "Requested Range Not Satisfiable"
            case 417:
                model.errorDescription = "Client Error :\nServer cannot meet requirements of Expect request-header field"
                model.errorLocalizedDescription = "Expectation Failed"
            case 418:
                model.errorDescription = "Client Error :\nI'm a teapot"
                model.errorLocalizedDescription = "I'm a Teapot"
            case 420:
                model.errorDescription = "Client Error :\nTwitter rate limiting"
                model.errorLocalizedDescription = "Enhance Your Calm"
            case 421:
                model.errorDescription = "Client Error :\nMisdirected Request"
                model.errorLocalizedDescription = "Misdirected Request"
            case 422:
                model.errorDescription = "Client Error :\nRequest unable to be followed due to semantic errors"
                model.errorLocalizedDescription = "Unprocessable Entity"
            case 423:
                model.errorDescription = "Client Error :\nResource that is being accessed is locked"
                model.errorLocalizedDescription = "Locked"
            case 424:
                model.errorDescription = "Client Error :\nRequest failed due to failure of a previous request"
                model.errorLocalizedDescription = "Failed Dependency"
            case 426:
                model.errorDescription = "Client Error :\nClient should switch to a different protocol"
                model.errorLocalizedDescription = "Upgrade Required"
            case 428:
                model.errorDescription = "Client Error :\nOrigin server requires the request to be conditional"
                model.errorLocalizedDescription = "Precondition Required"
            case 429:
                model.errorDescription = "Client Error :\nUser has sent too many requests in a given amount of time"
                model.errorLocalizedDescription = "Too Many Requests"
            case 431:
                model.errorDescription = "Client Error :\nServer is unwilling to process the request"
                model.errorLocalizedDescription = "Request Header Fields Too Large"
            case 444:
                model.errorDescription = "Client Error :\nServer returns no information and closes the connection"
                model.errorLocalizedDescription = "No Response"
            case 449:
                model.errorDescription = "Client Error :\nRequest should be retried after performing action"
                model.errorLocalizedDescription = "Retry With"
            case 450:
                model.errorDescription = "Client Error :\nWindows Parental Controls blocking access to the webpage"
                model.errorLocalizedDescription = "Blocked by Windows Parental Controls"
            case 451:
                model.errorDescription = "Client Error :\nThe server cannot reach the client's mailbox"
                model.errorLocalizedDescription = "Wrong Exchange server"
            case 499:
                model.errorDescription = "Client Error :\nConnection closed by the client while the HTTP server is processing"
                model.errorLocalizedDescription = "Client Closed Request"
            case 500:
                model.errorDescription = "Server Error :\nGeneric error message"
                model.errorLocalizedDescription = "Internal Server Error"
            case 501:
                model.errorDescription = "Server Error :\nServer does not recognize the method or lacks the ability to fulfill"
                model.errorLocalizedDescription = "Not Implemented"
            case 502:
                model.errorDescription = "Server Error :\nServer received an invalid response from the upstream server"
                model.errorLocalizedDescription = "Bad Gateway"
            case 503:
                model.errorDescription = "Server Error :\nServer is currently unavailable"
                model.errorLocalizedDescription = "Service Unavailable"
            case 504:
                model.errorDescription = "Server Error :\nGateway did not receive a response from the upstream server"
                model.errorLocalizedDescription = "Gateway Timeout"
            case 505:
                model.errorDescription = "Server Error :\nServer does not support the HTTP protocol version"
                model.errorLocalizedDescription = "HTTP Version Not Supported"
            case 506:
                model.errorDescription = "Server Error :\nContent negotiation for the request results in a circular reference"
                model.errorLocalizedDescription = "Variant Also Negotiates"
            case 507:
                model.errorDescription = "Server Error :\nServer is unable to store the representation"
                model.errorLocalizedDescription = "Insufficient Storage"
            case 508:
                model.errorDescription = "Server Error :\nServer detected an infinite loop while processing the request"
                model.errorLocalizedDescription = "Loop Detected"
            case 509:
                model.errorDescription = "Server Error :\nBandwidth limit exceeded"
                model.errorLocalizedDescription = "Bandwidth Limit Exceeded"
            case 510:
                model.errorDescription = "Server Error :\nFurther extensions to the request are required"
                model.errorLocalizedDescription = "Not Extended"
            case 511:
                model.errorDescription = "Server Error :\nClient needs to authenticate to gain network access"
                model.errorLocalizedDescription = "Network Authentication Required"
            case 526:
                model.errorDescription = "Server Error :\nThe origin web server does not have a valid SSL certificate"
                model.errorLocalizedDescription = "Invalid SSL certificate"
            case 598:
                model.errorDescription = "Server Error :\nNetwork read timeout behind the proxy"
                model.errorLocalizedDescription = "Network Read Timeout Error"
            case 599:
                model.errorDescription = "Server Error :\nNetwork connect timeout behind the proxy"
                model.errorLocalizedDescription = "Network Connect Timeout Error"
            default:
                break
            }
        }

        return model
    }

}
