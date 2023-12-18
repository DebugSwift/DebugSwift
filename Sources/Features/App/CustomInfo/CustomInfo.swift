//
//  CustomInfo.swift
//  DebugSwift
//
//  Created by Matheus Gois on 18/12/23.
//

import Foundation

public struct CustomData {
    public init(title: String, infos: [Info]) {
        self.title = title
        self.infos = infos
    }

    let title: String
    let infos: [Info]
}

extension CustomData {
    public struct Info {
        public init(title: String, subtitle: String) {
            self.title = title
            self.subtitle = subtitle
        }

        let title: String
        let subtitle: String
    }
}
