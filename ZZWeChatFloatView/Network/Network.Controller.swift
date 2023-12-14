//
//  Performance.swift
//  ZZWeChatFloatView
//
//  Created by Matheus Gois on 14/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

class NetworkViewController: BaseController {

    override init() {
        super.init()
        setup()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red

    }

    func setup() {
        title = "Network"
        if #available(iOS 13.0, *) {
            tabBarItem = UITabBarItem(
                title: title,
                image: UIImage(systemName: "network"),
                tag: 0
            )
        } else {
            // Fallback on earlier versions
        }
    }
}
