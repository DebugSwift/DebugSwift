//
//  Configuration.swift
//  InAppViewDebugger
//
//  Created by Indragie Karunaratne on 4/4/19.
//  Copyright © 2019 Indragie Karunaratne. All rights reserved.
//

import Foundation

/// Configuration options for the in app view debugger.
public final class Configuration: NSObject {
    /// Configuration for the 3D snapshot view.
    @objc public var snapshotViewConfiguration = SnapshotViewConfiguration()

    /// Configuration for the hierarchy (tree) view.
    @objc public var hierarchyViewConfiguration = HierarchyViewConfiguration()
}
