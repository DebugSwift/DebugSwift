//
//  SnapshotView.swift
//  InAppViewDebugger
//
//  Created by Indragie Karunaratne on 3/31/19.
//  Copyright © 2019 Indragie Karunaratne. All rights reserved.
//

import UIKit
import SceneKit

protocol SnapshotViewDelegate: AnyObject {
    /// Called when an element is select by tapping on it.
    func snapshotView(_ snapshotView: SnapshotView, didSelectSnapshot snapshot: Snapshot)
    
    /// Called when an element is deselected by tapping on a different element or when
    /// tapping outside the interactive area.
    func snapshotView(_ snapshotView: SnapshotView, didDeselectSnapshot snapshot: Snapshot)
    
    /// Called when the user long presses on a element. This is handled by presenting an
    /// action sheet for the element.
    func snapshotView(_ snapshotView: SnapshotView, didLongPressSnapshot snapshot: Snapshot, point: CGPoint)
    
    /// Called when the view wants to present an alert controller.
    func snapshotView(_ snapshotView: SnapshotView, showAlertController alertController: UIAlertController)
}

/// A view that renders an interactive 3D representation of a UI element
/// hierarchy snapshot.
final class SnapshotView: UIView {
    public weak var delegate: SnapshotViewDelegate?
    
    private let configuration: SnapshotViewConfiguration
    private let snapshot: Snapshot
    private let sceneView = SCNView()
    private let spacingSlider = UISlider()
    private let depthSlider = RangeSlider()
    private let descriptionLabel = UILabel()
    
    private var snapshotIdentifierToNodesMap = [String: SnapshotNodes]()
    private var maximumDepth = 0 {
        didSet {
            let maxDepthFloat = Float(maximumDepth)
            depthSlider.allowableMaximumValue = maxDepthFloat
            depthSlider.maximumValue = maxDepthFloat
            depthSlider.minimumValue = 0.0
        }
    }
    private var highlightedNodes: SnapshotNodes?
    private var hideHeaderNodes: Bool
    private var hideBorderNodes: Bool = false
    private var suppressSelectionEvents = false
    
    // MARK: Initialization
    
    public init(snapshot: Snapshot, configuration: SnapshotViewConfiguration = SnapshotViewConfiguration()) {
        self.configuration = configuration
        self.snapshot = snapshot
        self.hideHeaderNodes = shouldHideHeaderNodes(zSpacing: configuration.zSpacing)
        
        super.init(frame: .zero)
        
        configureSceneView()
        configureSpacingSlider()
        configureDepthSlider()
        configureDescriptionLabel()
        configureTapGestureRecognizer()
        configureLongPressGestureRecognizer()
    }
    
    private func configureSceneView() {
        let scene = SCNScene()
        scene.background.contents = configuration.backgroundColor
        
        var depth = 0
        _ = snapshotNode(snapshot: snapshot,
                         parentSnapshot: nil,
                         rootNode: scene.rootNode,
                         parentSnapshotNode: nil,
                         depth: &depth,
                         snapshotIdentifierToNodesMap: &snapshotIdentifierToNodesMap,
                         configuration: configuration,
                         hideHeaderNodes: hideHeaderNodes)
        maximumDepth = depth
        sceneView.scene = scene
        sceneView.allowsCameraControl = true
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sceneView)
        
        NSLayoutConstraint.activate([
            sceneView.leadingAnchor.constraint(equalTo: leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: trailingAnchor),
            sceneView.topAnchor.constraint(equalTo: topAnchor),
            sceneView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func configureSpacingSlider() {
        spacingSlider.minimumValue = configuration.minimumZSpacing
        spacingSlider.maximumValue = configuration.maximumZSpacing
        spacingSlider.isContinuous = true
        spacingSlider.addTarget(self, action: #selector(spacingSliderChanged(sender:)), for: .valueChanged)
        spacingSlider.setValue(configuration.zSpacing, animated: false)
        spacingSlider.translatesAutoresizingMaskIntoConstraints = false
        addSubview(spacingSlider)
        
        NSLayoutConstraint.activate([
            spacingSlider.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10.0),
            spacingSlider.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -8.0),
        ])
    }
    
    private func configureDepthSlider() {
        let maxDepthFloat = Float(maximumDepth)
        depthSlider.allowableMinimumValue = 0.0
        depthSlider.allowableMaximumValue = maxDepthFloat
        depthSlider.minimumValue = 0.0
        depthSlider.maximumValue = maxDepthFloat
        depthSlider.addTarget(self, action: #selector(depthSliderChanged(sender:)), for: .valueChanged)
        depthSlider.translatesAutoresizingMaskIntoConstraints = false
        addSubview(depthSlider)
        
        NSLayoutConstraint.activate([
            depthSlider.leadingAnchor.constraint(equalTo: spacingSlider.trailingAnchor, constant: 10.0),
            depthSlider.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -3.0),
            depthSlider.centerYAnchor.constraint(equalTo: spacingSlider.centerYAnchor, constant: 1.0),
            depthSlider.widthAnchor.constraint(equalTo: spacingSlider.widthAnchor, constant: 0.0)
        ])
    }
    
    private func configureDescriptionLabel() {
        descriptionLabel.font = configuration.descriptionFont
        descriptionLabel.textAlignment = .center
        descriptionLabel.adjustsFontSizeToFitWidth = true
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            descriptionLabel.bottomAnchor.constraint(equalTo: spacingSlider.topAnchor, constant: -5.0),
            descriptionLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 5.0),
            descriptionLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -5.0),
        ])
    }
    
    private func configureTapGestureRecognizer() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    private func configureLongPressGestureRecognizer() {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))
        addGestureRecognizer(longPressGestureRecognizer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: API
    
    func select(snapshot: Snapshot) {
        guard let node = snapshotIdentifierToNodesMap[snapshot.identifier]?.snapshotNode else {
            return
        }
        suppressSelectionEvents = true
        highlight(snapshotNode: node)
        suppressSelectionEvents = false
    }
    
    func deselect(snapshot: Snapshot) {
        if highlightedNodes?.snapshot === snapshot {
            suppressSelectionEvents = true
            highlight(snapshotNode: nil)
            suppressSelectionEvents = false
        }
    }
    
    func deselectAll() {
        highlight(snapshotNode: nil)
    }
    
    // MARK: Gesture Recognizer Actions
    
    @objc private func handleTap(sender: UITapGestureRecognizer) {
        guard sender.state == .ended else {
            return
        }
        let point = sender.location(ofTouch: 0, in: sceneView)
        highlight(snapshotNode: snapshotNodeAtPoint(point))
    }
    
    @objc private func handleLongPress(sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else {
            return
        }
        let point = sender.location(ofTouch: 0, in: sceneView)
        showActionSheet(snapshotNode: snapshotNodeAtPoint(point), point: point)
    }
    
    // MARK: Menu Item Actions
    
    private func showHideHeaderNodes(sender: UIAlertAction) {
        hideHeaderNodes = !hideHeaderNodes
        
        for (_, nodes) in snapshotIdentifierToNodesMap {
            nodes.headerNode?.isHidden = hideHeaderNodes
        }
    }
    
    private func showHideBorderNodes(sender: UIAlertAction) {
        hideBorderNodes = !hideBorderNodes
        
        for (_, nodes) in snapshotIdentifierToNodesMap {
            nodes.borderNode?.isHidden = hideBorderNodes
        }
    }

    // MARK: UIControl Actions
    
    @objc private func spacingSliderChanged(sender: UISlider) {
        if shouldHideHeaderNodes(zSpacing: sender.value) {
            hideHeaderNodes = true
        }
        
        for (_, nodes) in snapshotIdentifierToNodesMap {
            if let snapshotNode = nodes.snapshotNode {
                snapshotNode.position = {
                    var position = snapshotNode.position
                    position.z = max(sender.value, smallZOffset) * Float(nodes.depth)
                    return position
                }()
            }
            if hideHeaderNodes, let headerNode = nodes.headerNode {
                headerNode.isHidden = true
            }
        }
    }
    
    @objc private func depthSliderChanged(sender: RangeSlider) {
        let range = Int(floor(sender.minimumValue))...Int(ceil(sender.maximumValue))
        for (_, nodes) in snapshotIdentifierToNodesMap {
            nodes.snapshotNode?.isHidden = !range.contains(maximumDepth - nodes.depth)
        }
    }
    
    // MARK: Helper
    
    private func snapshotNodeAtPoint(_ point: CGPoint) -> SCNNode? {
        let hitTestResult = sceneView.hitTest(point, options: nil)
        for result in hitTestResult {
            if let snapshotNode = findNearestAncestorSnapshotNode(node: result.node) {
                return snapshotNode
            }
        }
        return nil
    }
    
    private func highlight(snapshotNode: SCNNode?) {
        if let previousNodes = highlightedNodes {
            if snapshotNode == previousNodes.snapshotNode {
                return
            }
            previousNodes.highlightNode?.removeFromParentNode()
            previousNodes.highlightNode = nil
            
            if !suppressSelectionEvents && snapshotNode == nil {
                delegate?.snapshotView(self, didDeselectSnapshot: previousNodes.snapshot)
            }
            highlightedNodes = nil
            descriptionLabel.text = nil
            setNeedsLayout()
        }
        
        guard let identifier = snapshotNode?.name, let nodes = snapshotIdentifierToNodesMap[identifier] else {
            return
        }
        
        let highlight = highlightNode(snapshot: nodes.snapshot, color: configuration.highlightColor)
        nodes.snapshotNode?.addChildNode(highlight)
        nodes.highlightNode = highlight
        highlightedNodes = nodes
        
        descriptionLabel.text = nodes.snapshot.element.shortDescription
        setNeedsLayout()
        
        if !suppressSelectionEvents {
            delegate?.snapshotView(self, didSelectSnapshot: nodes.snapshot)
        }
    }
    
    private func showActionSheet(snapshotNode: SCNNode?, point: CGPoint) {
        if let identifier = snapshotNode?.name, let nodes = snapshotIdentifierToNodesMap[identifier] {
            highlight(snapshotNode: snapshotNode)
            delegate?.snapshotView(self, didLongPressSnapshot: nodes.snapshot, point: point)
        } else {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            globalActions().forEach(alert.addAction)
            let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel the action"), style: .cancel, handler: nil)
            alert.addAction(cancel)
            alert.preferredAction = cancel
            alert.popoverPresentationController?.sourceView = self
            alert.popoverPresentationController?.sourceRect = CGRect(origin: point, size: .zero)
            delegate?.snapshotView(self, showAlertController: alert)
        }
    }
    
    private func globalActions() -> [UIAlertAction] {
        let headerItemTitle: String
        if hideHeaderNodes {
            headerItemTitle = NSLocalizedString("Show Headers", comment: "Show the headers above each UI element")
        } else {
            headerItemTitle = NSLocalizedString("Hide Headers", comment: "Hide the headers above each UI element")
        }
        
        let borderItemTitle: String
        if hideBorderNodes {
            borderItemTitle = NSLocalizedString("Show Borders", comment: "Show the borders around each UI element")
        } else {
            borderItemTitle = NSLocalizedString("Hide Borders", comment: "Hide the borders around each UI element")
        }
        
        return [
            UIAlertAction(title: headerItemTitle, style: .default, handler: showHideHeaderNodes),
            UIAlertAction(title: borderItemTitle, style: .default, handler: showHideBorderNodes),
        ]
    }
}

/// Container that holds references to the SceneKit nodes associated with a
/// snapshot.
private final class SnapshotNodes {
    let snapshot: Snapshot
    let depth: Int
    
    weak var snapshotNode: SCNNode?
    weak var headerNode: SCNNode?
    weak var borderNode: SCNNode?
    weak var highlightNode: SCNNode?
    
    init(snapshot: Snapshot, depth: Int) {
        self.snapshot = snapshot
        self.depth = depth
    }
}

/// This value is chosen such that this offset can be applied to avoid z-fighting
/// amongst nodes at the same z-position, but small enough that they appear to
/// visually be on the same plane.
private let smallZOffset: Float = 0.5

/// Returns whether the header nodes should be hidden for a given z-axis spacing.
private func shouldHideHeaderNodes(zSpacing: Float) -> Bool {
    return zSpacing <= smallZOffset
}

/// Returns the nearest ancestor snapshot node starting at the specified node.
private func findNearestAncestorSnapshotNode(node: SCNNode?) -> SCNNode? {
    guard let node = node else {
        return nil
    }
    if node.name != nil {
        return node
    }
    return findNearestAncestorSnapshotNode(node: node.parent)
}

/// Returns a node that renders a highlight overlay over a specified snapshot.
private func highlightNode(snapshot: Snapshot, color: UIColor) -> SCNNode {
    let path = UIBezierPath(rect: CGRect(origin: .zero, size: snapshot.frame.size))
    let shape = SCNShape(path: path, extrusionDepth: 0.0)
    
    let material = SCNMaterial()
    material.isDoubleSided = true
    material.diffuse.contents = color
    shape.insertMaterial(material, at: 0)
    
    let node = SCNNode(geometry: shape)
    node.position = SCNVector3(x: 0.0, y: 0.0, z: smallZOffset)
    return node
}

/// Returns a SceneKit node that recursively renders a hierarchy of UI elements
/// starting at the specified snapshot.
private func snapshotNode(snapshot: Snapshot,
                          parentSnapshot: Snapshot?,
                          rootNode: SCNNode,
                          parentSnapshotNode: SCNNode?,
                          depth: inout Int,
                          snapshotIdentifierToNodesMap: inout [String: SnapshotNodes],
                          configuration: SnapshotViewConfiguration,
                          hideHeaderNodes: Bool) -> SCNNode? {
    // Ignore elements that are not visible. These should appear in
    // the tree view, but not in the 3D view.
    if snapshot.isHidden || snapshot.frame.size == .zero {
        return nil
    }
    // Create a node whose contents are the snapshot of the element.
    let node = snapshotNode(snapshot: snapshot)
    node.name = snapshot.identifier
    
    let nodes = SnapshotNodes(snapshot: snapshot, depth: depth)
    nodes.snapshotNode = node
    
    // The node must be added to the root node for the coordinate
    // space calculations below to work.
    rootNode.addChildNode(node)
    node.position = {
        // Flip the y-coordinate since the SceneKit coordinate system has
        // a flipped version of the UIKit coordinate system.
        let y: CGFloat
        if let parentSnapshot = parentSnapshot {
            y = parentSnapshot.frame.height - snapshot.frame.maxY
        } else {
            y = 0.0
        }
        
        // To simplify calculating the z-axis spacing between the layers, we
        // make each snapshot node a direct child of the root rather than embedding
        // the nodes in their parent nodes in the same structure as the UI elements
        // themselves. With this flattened hierarchy, the z-position can be
        // calculated for every node simply by multiplying the spacing by the depth.
        //
        // `parentSnapshotNode` as referenced here is **not** the actual parent
        // node of `node`, it is the node **corresponding to** the parent of the
        // UI element. It is used to convert from frame coordinates, which are
        // relative to the bounds of the parent, to coordinates relative to the
        // root node.
        let positionRelativeToParent = SCNVector3(snapshot.frame.origin.x, y, 0.0)
        var positionRelativeToRoot: SCNVector3
        if let parentSnapshotNode = parentSnapshotNode {
            positionRelativeToRoot = rootNode.convertPosition(positionRelativeToParent, from: parentSnapshotNode)
        } else {
            positionRelativeToRoot = positionRelativeToParent
        }
        positionRelativeToRoot.z = Float(configuration.zSpacing) * Float(depth)
        return positionRelativeToRoot
    }()
    
    let headerAttributes: SnapshotViewConfiguration.HeaderAttributes
    switch snapshot.label.classification {
    case .normal:
        headerAttributes = configuration.normalHeaderAttributes
    case .important:
        headerAttributes = configuration.importantHeaderAttributes
    }
    
    let border = borderNode(node: node, color: headerAttributes.color)
    node.addChildNode(border)
    nodes.borderNode = border
    
    if let header = headerNode(snapshot: snapshot,
                               attributes: headerAttributes) {
        node.addChildNode(header)
        nodes.headerNode = header
        if hideHeaderNodes {
            header.isHidden = true
        }
    }
    
    snapshotIdentifierToNodesMap[snapshot.identifier] = nodes
    
    var frames = [CGRect]()
    var maxChildDepth = depth
    snapshot.children.forEach { child in
        var childDepth: Int
        // Children that intersect a sibling should be rendered in
        // a separate layer, above the previous siblings.
        if frames.first(where: { $0.intersects(child.frame) }) != nil {
            childDepth = maxChildDepth + 1
        } else {
            childDepth = depth + 1
        }
        
        if let _ = snapshotNode(snapshot: child,
                                parentSnapshot: snapshot,
                                rootNode: rootNode,
                                parentSnapshotNode: node,
                                depth: &childDepth,
                                snapshotIdentifierToNodesMap: &snapshotIdentifierToNodesMap,
                                configuration: configuration,
                                hideHeaderNodes: hideHeaderNodes) {
            maxChildDepth = max(maxChildDepth, childDepth)
            frames.append(child.frame)
        }
    }
    depth = maxChildDepth
    return node
}

/// Returns a node that renders a snapshot image.
private func snapshotNode(snapshot: Snapshot) -> SCNNode {
    let path = UIBezierPath(rect: CGRect(origin: .zero, size: snapshot.frame.size))
    let shape = SCNShape(path: path, extrusionDepth: 0.0)
    let material = SCNMaterial()
    material.isDoubleSided = true
    if let snapshot = snapshot.snapshotImage {
        material.diffuse.contents = snapshot
    } else {
        material.diffuse.contents = UIColor.white
    }
    shape.insertMaterial(material, at: 0)
    return SCNNode(geometry: shape)
}

/// Returns a node that draws a line between two vertices.
private func lineFrom(vertex vertex1: SCNVector3, toVertex vertex2: SCNVector3, color: UIColor) -> SCNNode
{
    let indices: [Int32] = [0, 1]
    let source = SCNGeometrySource(vertices: [vertex1, vertex2])
    let element = SCNGeometryElement(indices: indices, primitiveType: .line)
    
    let geometry = SCNGeometry(sources: [source], elements: [element])
    let material = SCNMaterial()
    material.diffuse.contents = color
    material.isDoubleSided = true
    geometry.insertMaterial(material, at: 0)
    
    return SCNNode(geometry: geometry)
}

/// Returns an array of nodes that can be used to render a colored
/// border around the specified node.
private func borderNode(node: SCNNode, color: UIColor) -> SCNNode {
    let (min, max) = node.boundingBox;
    let topLeft = SCNVector3(x: min.x, y: max.y, z: smallZOffset)
    let bottomLeft = SCNVector3(x: min.x, y: min.y, z: smallZOffset)
    let topRight = SCNVector3(x: max.x, y: max.y, z: smallZOffset)
    let bottomRight = SCNVector3(x: max.x, y: min.y, z: smallZOffset)
    
    let bottom = lineFrom(vertex: bottomLeft, toVertex: bottomRight, color: color)
    let left = lineFrom(vertex: bottomLeft, toVertex: topLeft, color: color)
    let right = lineFrom(vertex: bottomRight, toVertex: topRight, color: color)
    let top = lineFrom(vertex: topLeft, toVertex: topRight, color: color)
    
    let border = SCNNode()
    border.addChildNode(bottom)
    border.addChildNode(left)
    border.addChildNode(right)
    border.addChildNode(top)
    return border
}

/// Returns a node that renders a header above a snapshot node.
/// The header contains the name text from the element, if specified.
private func headerNode(snapshot: Snapshot,
                        attributes: SnapshotViewConfiguration.HeaderAttributes) -> SCNNode? {
    guard let text = nameTextGeometry(label: snapshot.label, font: attributes.font) else {
        return nil
    }
    
    let textNode = SCNNode(geometry: text)
    let (textMin, textMax) = textNode.boundingBox
    let textWidth = textMax.x - textMin.x
    let textHeight = textMax.y - textMin.y
    
    let snapshotWidth = snapshot.frame.width
    let headerWidth = max(snapshotWidth, CGFloat(textWidth))
    let frame = CGRect(x: 0.0, y: 0.0, width: headerWidth, height: CGFloat(textHeight) + (attributes.verticalInset * 2.0))
    let headerNode = SCNNode(geometry: nameHeaderShape(frame: frame, color: attributes.color, cornerRadius: attributes.cornerRadius))
    
    textNode.position = SCNVector3(
        x: (Float(frame.width) / 2.0) - (textWidth / 2.0),
        y: (Float(frame.height) / 2.0) - (textHeight / 2.0),
        z: smallZOffset
    )
    headerNode.addChildNode(textNode)
    
    headerNode.position = SCNVector3(
        x: Float((snapshotWidth / 2.0) - (headerWidth / 2.0)),
        y: Float(snapshot.frame.height),
        z: smallZOffset
    )
    return headerNode
}

/// Returns a shape that is used to render the background of the header.
private func nameHeaderShape(frame: CGRect, color: UIColor, cornerRadius: CGFloat) -> SCNShape {
    let path = UIBezierPath(roundedRect: frame, byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
    let shape = SCNShape(path: path, extrusionDepth: 0.0)
    let material = SCNMaterial()
    material.isDoubleSided = true
    material.diffuse.contents = color
    shape.insertMaterial(material, at: 0)
    return shape
}

/// Returns a text geometry used to render text inside the header.
private func nameTextGeometry(label: ElementLabel, font: UIFont) -> SCNText? {
    guard let name = label.name else {
        return nil
    }
    let text = SCNText()
    text.string = name
    text.font = font
    text.alignmentMode = CATextLayerAlignmentMode.center.rawValue
    text.truncationMode = CATextLayerTruncationMode.end.rawValue
    return text
}
