//
//  UIImage+.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import UIKit

extension UIImage {
    convenience init?(named imageName: String) {
        if #available(iOS 13.0, *) {
            self.init(systemName: imageName)
        } else {
            return nil
        }
    }
}
