//
//  TreeTableViewDataSource.swift
//  InAppViewDebugger
//
//  Created by Indragie Karunaratne on 4/6/19.
//  Copyright © 2019 Indragie Karunaratne. All rights reserved.
//

import UIKit

protocol Tree {
    var children: [Self] { get }
}

final class TreeTableViewDataSource<TreeType: Tree>: NSObject, UITableViewDataSource {
    typealias CellFactory = (UITableView /* tableView */, TreeType /* value */, Int /* depth */, IndexPath /* indexPath */, Bool /* isCollapsed */ ) -> UITableViewCell

    private let tree: TreeType
    private let cellFactory: CellFactory
    private let flattenedTree: [FlattenedTree<TreeType>]

    init(tree: TreeType, maxDepth: Int?, cellFactory: @escaping CellFactory) {
        self.tree = tree
        self.cellFactory = cellFactory
        self.flattenedTree = flatten(tree: tree, depth: 0, maxDepth: maxDepth)
    }

    func value(atIndexPath indexPath: IndexPath) -> TreeType {
        flattenedTree[indexPath.row].value
    }

    // MARK: UITableViewDataSource

    func numberOfSections(in _: UITableView) -> Int {
        1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        flattenedTree.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tree = flattenedTree[indexPath.row]
        return cellFactory(tableView, tree.value, tree.depth, indexPath, tree.isCollapsed)
    }
}

extension TreeTableViewDataSource where TreeType: AnyObject {
    func indexPath(forValue value: TreeType) -> IndexPath? {
        flattenedTree
            .firstIndex { $0.value === value }
            .flatMap { IndexPath(row: $0, section: .zero) }
    }
}

private struct FlattenedTree<TreeType: Tree> {
    let value: TreeType
    let depth: Int
    var isCollapsed = false

    init(value: TreeType, depth: Int) {
        self.value = value
        self.depth = depth
    }
}

private func flatten<TreeType: Tree>(tree: TreeType, depth: Int = 0, maxDepth: Int?) -> [FlattenedTree<TreeType>] {
    let initial = [FlattenedTree<TreeType>(value: tree, depth: depth)]
    let childDepth = depth + 1
    if let maxDepth, childDepth > maxDepth {
        return initial
    }
    return tree.children.reduce(initial) { result, child in
        var newResult = result
        newResult.append(contentsOf: flatten(tree: child, depth: childDepth, maxDepth: maxDepth))
        return newResult
    }
}
