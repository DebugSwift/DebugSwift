//
//  App.ViewModel.swift
//  DebugSwift
//
//  Created by Matheus Gois on 16/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

class AppViewModel: NSObject {
    var infos: [UserInfo.Info] {
        UserInfo.infos
    }

    var customInfos: [CustomData] {
        DebugSwift.App.customInfo?() ?? []
    }

    func getTitle(for section: Int) -> String? {
        let data = AppViewController.Sections(rawValue: section)
        switch data {
        case .customData:
            return customInfos.isEmpty ? nil : data?.title
        default:
            return data?.title
        }
    }
}
