//
//  ExpandableTreeDataSource.swift
//  DebugSwift
//
//  Created by Matheus Gois
//

import UIKit

final class ExpandableTreeDataSource<TreeType: Tree & AnyObject>: NSObject, UITableViewDataSource {
    typealias CellFactory = (UITableView, TreeType, Int, IndexPath, Bool) -> UITableViewCell
    
    private let rootTree: TreeType
    private let cellFactory: CellFactory
    private var expandedNodes: Set<ObjectIdentifier> = []
    private var flattenedTree: [TreeNode<TreeType>] = []
    
    init(tree: TreeType, cellFactory: @escaping CellFactory) {
        self.rootTree = tree
        self.cellFactory = cellFactory
        super.init()
        rebuildFlattenedTree()
    }
    
    // MARK: - Public API
    
    func isExpanded(_ value: TreeType) -> Bool {
        expandedNodes.contains(ObjectIdentifier(value))
    }
    
    func toggleExpansion(_ value: TreeType) -> [IndexPath] {
        let identifier = ObjectIdentifier(value)
        
        if expandedNodes.contains(identifier) {
            expandedNodes.remove(identifier)
        } else {
            expandedNodes.insert(identifier)
        }
        
        let previousTree = flattenedTree
        rebuildFlattenedTree()
        
        return calculateIndexPathChanges(from: previousTree, to: flattenedTree)
    }
    
    func value(atIndexPath indexPath: IndexPath) -> TreeType {
        flattenedTree[indexPath.row].value
    }
    
    func indexPath(forValue value: TreeType) -> IndexPath? {
        flattenedTree
            .firstIndex { $0.value === value }
            .map { IndexPath(row: $0, section: 0) }
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in _: UITableView) -> Int {
        1
    }
    
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        flattenedTree.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let node = flattenedTree[indexPath.row]
        let isExpanded = expandedNodes.contains(ObjectIdentifier(node.value))
        return cellFactory(tableView, node.value, node.depth, indexPath, isExpanded)
    }
    
    // MARK: - Private
    
    private func rebuildFlattenedTree() {
        flattenedTree = flattenTree(rootTree, depth: 0)
    }
    
    private func flattenTree(_ tree: TreeType, depth: Int) -> [TreeNode<TreeType>] {
        var result = [TreeNode(value: tree, depth: depth)]
        
        let identifier = ObjectIdentifier(tree)
        if expandedNodes.contains(identifier) {
            let childDepth = depth + 1
            for child in tree.children {
                if let typedChild = child as? TreeType {
                    result.append(contentsOf: flattenTree(typedChild, depth: childDepth))
                }
            }
        }
        
        return result
    }
    
    private func calculateIndexPathChanges(from oldTree: [TreeNode<TreeType>], to newTree: [TreeNode<TreeType>]) -> [IndexPath] {
        var changes: [IndexPath] = []
        
        let maxCount = max(oldTree.count, newTree.count)
        
        for i in 0..<maxCount {
            if i < oldTree.count && i < newTree.count {
                if oldTree[i].value !== newTree[i].value {
                    changes.append(IndexPath(row: i, section: 0))
                }
            } else {
                changes.append(IndexPath(row: i, section: 0))
            }
        }
        
        return changes
    }
}

// MARK: - TreeNode

private struct TreeNode<TreeType: Tree> {
    let value: TreeType
    let depth: Int
}
