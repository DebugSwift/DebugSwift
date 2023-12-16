//
//  CacheStoragePolicy.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

struct CacheHelper {
    /// Determines the cache storage policy for a response.
    /// When providing a response to the client, this function is used to tell the client whether
    /// the response is cacheable or not.
    /// - Parameters:
    ///   - request: The request that generated the response; must not be nil.
    ///   - response: The response itself; must not be nil.
    /// - Returns: A cache storage policy to use.
    static func cacheStoragePolicy(for request: URLRequest, and response: HTTPURLResponse) -> URLCache.StoragePolicy {
        var cacheable: Bool
        var result: URLCache.StoragePolicy

        // First determine if the request is cacheable based on its status code.
        switch response.statusCode {
        case 200, 203, 206, 301, 304, 404, 410:
            cacheable = true
        default:
            cacheable = false
        }

        // If the response might be cacheable, look at the "Cache-Control" header in the response.
        if cacheable {
            let responseHeader = (response.allHeaderFields["Cache-Control"] as? String)?.lowercased()
            if let responseHeader = responseHeader, responseHeader.range(of: "no-store") != nil {
                cacheable = false
            }
        }

        // If we still think it might be cacheable, look at the "Cache-Control" header in the request.
        if cacheable {
            let requestHeader = (request.allHTTPHeaderFields?["Cache-Control"] as? String)?.lowercased()
            if let requestHeader = requestHeader,
               requestHeader.range(of: "no-store") != nil,
               requestHeader.range(of: "no-cache") != nil {
                cacheable = false
            }
        }

        // Use the cacheable flag to determine the result.
        if cacheable {
            // This code only caches HTTPS data in memory. This is in line with earlier versions of iOS.
            // Modern versions of iOS use file protection to protect the cache, and thus are happy to cache HTTPS on disk.
            // I've not made the corresponding change because it's nice to see all three cache policies in action.
            if request.url?.scheme?.lowercased() == "https" {
                result = .allowedInMemoryOnly
            } else {
                result = .allowed
            }
        } else {
            result = .notAllowed
        }

        return result
    }
}
