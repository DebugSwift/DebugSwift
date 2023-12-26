//
//  UIImage+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

extension UIImage {
    static func named(_ imageName: String, default: String? = nil) -> UIImage? {
        if #available(iOS 13.0, *) {
            return UIImage.init(systemName: imageName)
        } else {
            return `default`?.image(with: [.foregroundColor: UIColor.white])
        }
    }
}
