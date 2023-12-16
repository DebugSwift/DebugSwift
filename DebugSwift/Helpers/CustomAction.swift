//
//  CustomAction.swift
//  DebugSwift
//
//  Created by Matheus Gois on 16/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation

typealias CustomActionBody = () -> Void

class CustomAction {

    // MARK: - Properties

    private(set) var name: String
    private var body: CustomActionBody?

    // MARK: - Initialization

    init(name: String, body: CustomActionBody?) {
        self.name = name
        self.body = body
    }

    class func customAction(withName name: String, body: CustomActionBody?) -> CustomAction {
        return CustomAction(name: name, body: body)
    }

    // MARK: - Performing action

    func perform() {
        body?()
    }
}
