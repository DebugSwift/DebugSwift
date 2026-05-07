//
//  App.CustomAction.Model.swift
//  DebugSwift
//
//  Created by Matheus Gois on 16/01/24.
//

import Foundation

public struct CustomAction {
    public init(title: String, actions: Actions) {
        self.title = title
        self.actions = actions
    }

    let title: String
    let actions: Actions
}

extension CustomAction {
    public typealias Actions = [Action]

    public struct Action {
        public init(title: String, action: (() -> Void)?) {
            self.title = title
            self.action = action
        }

        let title: String
        let action: (() -> Void)?
    }
}
