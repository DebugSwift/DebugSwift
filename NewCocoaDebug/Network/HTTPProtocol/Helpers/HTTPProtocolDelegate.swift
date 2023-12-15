//
//  CustomHTTPProtocolDelegate.swift
//  NewCocoaDebug
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

protocol CustomHTTPProtocolDelegate: AnyObject {
    func customHTTPProtocol(_ proto: CustomHTTPProtocol, didReceive response: URLResponse)
    func customHTTPProtocol(_ proto: CustomHTTPProtocol, didReceive data: Data)
    func customHTTPProtocolDidFinishLoading(_ proto: CustomHTTPProtocol)
    func customHTTPProtocol(_ proto: CustomHTTPProtocol, didFailWithError error: Error)
}
