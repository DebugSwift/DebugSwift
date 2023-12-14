//
//  App.Controller.swift
//  ZZWeChatFloatView
//
//  Created by Matheus Gois on 14/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

class AppViewController: BaseController {

    override init() {
        super.init()
        setup()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .purple
    }

    func setup() {
        title = "App"
        if #available(iOS 13.0, *) {
            tabBarItem = UITabBarItem(
                title: title,
                image: UIImage(systemName: "app"),
                tag: 4
            )
        } else {
            // Fallback on earlier versions
        }
    }
}
