//
//  CanonicalRequest.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

// MARK: - URL Canonicalization Steps

/// A step in the canonicalization process.
/// - Parameters:
///   - url: The original URL to work on.
///   - urlData: The URL as a mutable buffer; the routine modifies this.
///   - bytesInserted: The number of bytes that have been inserted so far in the mutable buffer.
/// - Returns: An updated value of bytesInserted or kCFNotFound if the URL must be reparsed.
typealias CanonicalRequestStepFunction = (
    _ url: URL, _ urlData: NSMutableData, _ bytesInserted: CFIndex
) -> CFIndex

enum RequestHelper {
    // MARK: - API

    /// Canonicalize the request.
    /// - Parameter request: The request to canonicalize.
    /// - Returns: The canonicalized request.
    static func canonicalRequest(for request: URLRequest) -> URLRequest {
        guard let result = (request as? NSMutableURLRequest)?.copy() as? NSMutableURLRequest else {
            fatalError("Failed to create a mutable copy of the request.")
        }

        // First up check that we're dealing with HTTP or HTTPS. If not, do nothing (why were we
        // we even called?).
        guard let scheme = request.url?.scheme?.lowercased(), scheme == "http" || scheme == "https"
        else {
            fatalError("Unsupported URL scheme.")
        }

        var bytesInserted: CFIndex = kCFNotFound
        var requestURL = request.url
        var urlData: NSMutableData?

        let stepFunctions: [CanonicalRequestStepFunction] = [
            fixPostSchemeSeparator,
            lowercaseScheme,
            lowercaseHost,
            fixEmptyHost,
            fixEmptyPath
        ]

        // Canonicalize the URL by executing each of our step functions.
        bytesInserted = kCFNotFound
        urlData = nil

        let stepCount = stepFunctions.count
        for (stepIndex, stepFunction) in stepFunctions.enumerated() {
            // If we don't have valid URL data, create it from the URL.
            if bytesInserted == kCFNotFound {
                guard let urlDataImmutable = CFURLCreateData(
                    nil, requestURL as CFURL?, CFStringBuiltInEncodings.UTF8.rawValue, true
                )
                else {
                    fatalError("Failed to create URL data.")
                }

                urlData = NSMutableData(data: urlDataImmutable as Data)
                bytesInserted = 0
            }

            // Run the step.
            bytesInserted = stepFunction(requestURL!, urlData!, bytesInserted)

            // If the step invalidated our URL (or we're on the last step, whereupon we'll need
            // the URL outside of the loop), recreate the URL from the URL data.
            if bytesInserted == kCFNotFound || (stepIndex + 1) == stepCount {
                guard let newRequestURL = CFURLCreateWithBytes(
                    nil, urlData!.bytes, CFIndex(urlData!.length), CFStringBuiltInEncodings.UTF8.rawValue,
                    nil
                )
                else {
                    fatalError("Failed to create URL from bytes.")
                }

                requestURL = newRequestURL as URL
                urlData = nil
            }
        }

        result.url = requestURL
        canonicalizeHeaders(result)
        return result as URLRequest
    }

    /// The post-scheme separate should be "://"; if that's not the case, fix it.
    /// - Parameters:
    ///   - url: The original URL to work on.
    ///   - urlData: The URL as a mutable buffer; the routine modifies this.
    ///   - bytesInserted: The number of bytes that have been inserted so far in the mutable buffer.
    /// - Returns: An updated value of bytesInserted or kCFNotFound if the URL must be reparsed.
    private static func fixPostSchemeSeparator(
        _ url: URL, _ urlData: NSMutableData, _ bytesInserted: CFIndex
    ) -> CFIndex {
        var urlDataBytes: UnsafeMutablePointer<UInt8>?
        var urlDataLength: Int
        var cursor: Int
        var separatorLength: Int
        var expectedSeparatorLength: Int

        let range = CFURLGetByteRangeForComponent(url as CFURL, .scheme, nil)
        guard range.location != kCFNotFound else {
            return bytesInserted
        }

        urlDataBytes = urlData.mutableBytes.assumingMemoryBound(to: UInt8.self)
        urlDataLength = urlData.length

        separatorLength = 0
        cursor = Int(range.location) + Int(bytesInserted) + Int(range.length)
        if cursor < urlDataLength, urlDataBytes![cursor] == 58 { // ASCII code for ':'
            cursor += 1
            separatorLength += 1
            if cursor < urlDataLength, urlDataBytes![cursor] == 47 { // ASCII code for '/'
                cursor += 1
                separatorLength += 1
                if cursor < urlDataLength, urlDataBytes![cursor] == 47 { // ASCII code for '/'
                    cursor += 1
                    separatorLength += 1
                }
            }
        }

        expectedSeparatorLength = 3 // Length of "://"
        if separatorLength != expectedSeparatorLength {
            urlData.replaceBytes(
                in: NSRange(
                    location: Int(range.location) + Int(bytesInserted) + Int(range.length),
                    length: separatorLength
                ), withBytes: ":/", length: expectedSeparatorLength
            )
            return kCFNotFound // have to build everything now
        }

        return bytesInserted
    }

    /// The scheme should be lowercase; if it's not, make it so.
    /// - Parameters:
    ///   - url: The original URL to work on.
    ///   - urlData: The URL as a mutable buffer; the routine modifies this.
    ///   - bytesInserted: The number of bytes that have been inserted so far in the mutable buffer.
    /// - Returns: An updated value of bytesInserted or kCFNotFound if the URL must be reparsed.
    private static func lowercaseScheme(
        _ url: URL, _ urlData: NSMutableData, _ bytesInserted: CFIndex
    ) -> CFIndex {
        let range = CFURLGetByteRangeForComponent(url as CFURL, .scheme, nil)
        guard range.location != kCFNotFound else {
            return bytesInserted
        }

        let urlDataBytes = urlData.mutableBytes.assumingMemoryBound(to: UInt8.self)
        for i in Int(range.location) + Int(bytesInserted)..<Int(range.location) + Int(bytesInserted)
            + Int(range.length) {
            urlDataBytes[i] = UInt8(tolower_l(Int32(urlDataBytes[i]), nil))
        }

        return bytesInserted
    }

    /// The host should be lowercase; if it's not, make it so.
    /// - Parameters:
    ///   - url: The original URL to work on.
    ///   - urlData: The URL as a mutable buffer; the routine modifies this.
    ///   - bytesInserted: The number of bytes that have been inserted so far in the mutable buffer.
    /// - Returns: An updated value of bytesInserted or kCFNotFound if the URL must be reparsed.
    private static func lowercaseHost(_ url: URL, _ urlData: NSMutableData, _ bytesInserted: CFIndex)
        -> CFIndex {
        let range = CFURLGetByteRangeForComponent(url as CFURL, .host, nil)
        guard range.location != kCFNotFound else {
            return bytesInserted
        }

        let urlDataBytes = urlData.mutableBytes.assumingMemoryBound(to: UInt8.self)
        for i in Int(range.location) + Int(bytesInserted)..<Int(range.location) + Int(bytesInserted)
            + Int(range.length) {
            urlDataBytes[i] = UInt8(tolower_l(Int32(urlDataBytes[i]), nil))
        }

        return bytesInserted
    }

    /// An empty host should be treated as "localhost" case; if it's not, make it so.
    /// - Parameters:
    ///   - url: The original URL to work on.
    ///   - urlData: The URL as a mutable buffer; the routine modifies this.
    ///   - bytesInserted: The number of bytes that have been inserted so far in the mutable buffer.
    /// - Returns: An updated value of bytesInserted or kCFNotFound if the URL must be reparsed.
    private static func fixEmptyHost(_ url: URL, _ urlData: NSMutableData, _ bytesInserted: CFIndex)
        -> CFIndex {
        let range = CFURLGetByteRangeForComponent(url as CFURL, .host, nil)
        guard range.length == 0 else {
            return bytesInserted
        }

        let localhostLength = 9 // Length of "localhost"
        let rangeWithSeparator = CFRange()

        if range.location != kCFNotFound {
            urlData.replaceBytes(
                in: NSRange(location: Int(range.location) + Int(bytesInserted), length: 0),
                withBytes: "localhost", length: localhostLength
            )
            return bytesInserted + localhostLength
        } else if range.length == 0 {
            let localhostLength = strlen("localhost")
            urlData.replaceBytes(
                in: NSRange(location: Int(rangeWithSeparator.location) + Int(bytesInserted), length: 0),
                withBytes: "localhost",
                length: localhostLength
            )
            return bytesInserted + localhostLength
        }

        return bytesInserted
    }

    /// Transform an empty URL path to "/". For example, "http://www.apple.com" becomes "http://www.apple.com/".
    /// - Parameters:
    ///   - url: The original URL to work on.
    ///   - urlData: The URL as a mutable buffer; the routine modifies this.
    ///   - bytesInserted: The number of bytes that have been inserted so far in the mutable buffer.
    /// - Returns: An updated value of bytesInserted or kCFNotFound if the URL must be reparsed.
    private static func fixEmptyPath(_ url: URL, _ urlData: NSMutableData, _ bytesInserted: CFIndex)
        -> CFIndex {
        var rangeWithSeparator = CFRange()
        let range = CFURLGetByteRangeForComponent(url as CFURL, .path, &rangeWithSeparator)

        // The following is not a typo. We use rangeWithSeparator to find where to insert the "/"
        // and the range length to decide whether we /need/ to insert the "/".
        if range.location != kCFNotFound, rangeWithSeparator.length == 0 {
            urlData.replaceBytes(
                in: NSRange(location: Int(rangeWithSeparator.location) + Int(bytesInserted), length: 0),
                withBytes: "/",
                length: 1
            )
            return bytesInserted + 1
        }
        return bytesInserted
    }

    // MARK: - Other Request Canonicalization

    /// Canonicalize the request headers.
    /// - Parameter request: The request to canonicalize.
    private static func canonicalizeHeaders(_ request: NSMutableURLRequest) {
        // If there's no content type and the request is a POST with a body, add a default
        // content type of "application/x-www-form-urlencoded".
        if request.value(forHTTPHeaderField: "Content-Type") == nil,
           request.httpMethod.caseInsensitiveCompare("POST") == .orderedSame,
           request.httpBody != nil || request.httpBodyStream != nil {
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        }

        // If there's no "Accept" header, add a default.
        if request.value(forHTTPHeaderField: "Accept") == nil {
            request.setValue("*/*", forHTTPHeaderField: "Accept")
        }

        // If there's not "Accept-Encoding" header, add a default.
        if request.value(forHTTPHeaderField: "Accept-Encoding") == nil {
            request.setValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
        }

        // If there's not an "Accept-Language" headre, add a default. This is quite bogus; ideally we
        // should derive the correct "Accept-Language" value from the language that the app is running
        // in. However, that's quite difficult to get right, so rather than show some general-purpose
        // code that might fail in some circumstances, I've decided to just hardwire US English.
        // If you use this code in your own app you can customize it as you see fit. One option might be
        // to base this value on -[NSBundle preferredLocalizations], so that the web page comes back in
        // the language that the app is running in.
        if request.value(forHTTPHeaderField: "Accept-Language") == nil {
            request.setValue("en-us", forHTTPHeaderField: "Accept-Language")
        }
    }
}
