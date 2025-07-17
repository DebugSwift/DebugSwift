//
//  Performance.LeakDetector.swift
//
//  Created by Jan de Vries on 16/04/2022.
//

/// Reference: https://github.com/Janneman84/LeakedViewControllerDetector

import UIKit

public struct PerformanceLeak {
    public let controller: UIViewController?
    public let view: UIView?
    public let message: String

    init(
        controller: UIViewController? = nil,
        view: UIView? = nil,
        message: String
    ) {
        self.controller = controller
        self.view = view
        self.message = message
    }

    public var isDeallocation: Bool { controller == nil && view == nil }
}

class PerformanceLeakDetector: @unchecked Sendable {
    
    private init() {}
    static let shared = PerformanceLeakDetector()

    var callback: ((PerformanceLeak) -> Void)?
    var delay = 1.0
    var warningWindow: UIWindow?
    var lastBackgroundedDate = Date(timeIntervalSince1970: 0)
    var leaks = [LeakModel]()

    func setup() {
        NotificationCenter.lvcd.addObserver(
            self,
            selector: #selector(toBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    @objc private func toBackground() {
        lastBackgroundedDate = Date()
    }

    private var _ignoredWindowClassNames = [
        "UIRemoteKeyboardWindow",
        "UITextEffectsWindow"
    ]

    var ignoredWindowClassNames: [String] {
        get {
            _ignoredWindowClassNames
        }
        set {
            _ignoredWindowClassNames += newValue
        }
    }

    private var _ignoredViewControllerClassNames = [
        "UICompatibilityInputViewController",
        "_SFAppPasswordSavingViewController",
        "UIKeyboardHiddenViewController_Save",
        "_UIAlertControllerTextFieldViewController",
        "UISystemInputAssistantViewController",
        "UIPredictionViewController",
        "DebugSwift.TabBarController"
    ]
    var ignoredViewControllerClassNames: [String] {
        get {
            _ignoredViewControllerClassNames
        }
        set {
            _ignoredViewControllerClassNames += newValue
        }
    }

    private var _ignoredViewClassNames = [
        "PLTileContainerView",
        "CAMPreviewView",
        "_UIPointerInteractionAssistantEffectContainerView"
    ]
    var ignoredViewClassNames: [String] {
        get {
            _ignoredViewClassNames
        }
        set {
            _ignoredViewClassNames += newValue
        }
    }
}

extension UIView {
    /**
     Same as removeFromSuperview() but it also checks if it or any of its subviews don't deinit after the view is removed from the view tree. In that case the PerformanceLeakDetector warning callback will be triggered.

     Make sure you have set PerformanceLeakDetector.shared.onDetect(){}, preferably in AppDelegate's application(_:didFinishLaunchingWithOptions:), else it will act the same as regular removeFromSuperview() .

     Only use this method if the view is supposed to deinit shortly after it is removed from the view tree, or else it may trigger false warnings. In that case use regular removeFromSuperview() instead.

     */
    @objc public func removeFromSuperviewDetectLeaks() {
        let superViewWasNil = superview == nil && window == nil // check if view was removed already
        removeFromSuperview()

        // only check when app is active for now
        // callback may be nil on purpose, e.g. for release builds, so just ignore then
        if PerformanceLeakDetector.shared.callback != nil, !superViewWasNil, UIApplication.shared.applicationState == .active {
            checkForLeakedSubViews()
        }
    }
}

extension UIView {
    @objc fileprivate func checkForLeakedSubViews() {
        let delay = PerformanceLeakDetector.shared.delay

        iterateTopSubviews { topSubview in
            let startTime = Date()
            DispatchQueue.main.asyncAfter(
                deadline: .now() + delay
            ) { [
                weak topSubview,
                weak self
            ] in
                if
                    self == nil || self?.superview == nil,
                    self?.firstViewController == nil, // in case it switched VC
                    let leakedView = topSubview?.rootView,
                    leakedView == topSubview || !(leakedView is UIWindow), // prevents rare crash
                    leakedView.firstViewController == nil, // prevents false positives
                    objc_getAssociatedObject(leakedView, &LVCDDeallocator.key) == nil,
                    UIApplication.shared.applicationState == .active, // theoretically not needed when also checking lastBackgroundedDate, but just in case
                    PerformanceLeakDetector.shared.lastBackgroundedDate < startTime,
                    !PerformanceLeakDetector.shared.ignoredViewClassNames.contains(type(of: leakedView).description()) {
                    let errorTitle = "VIEW STILL IN MEMORY"
                    var errorMessage = leakedView.debugDescription.lvcdRemoveBundleAndModuleName()
                    if let bundleName = Bundle.main.infoDictionary?["CFBundleName"] {
                        errorMessage = errorMessage.replacingOccurrences(
                            of: "\(bundleName).",
                            with: ""
                        )
                    }

                    PerformanceLeakDetector.shared.callback?(
                        .init(
                            view: leakedView,
                            message: "\(errorTitle) \(errorMessage)"
                        )
                    )
                    Debug.print("\(errorTitle) \(errorMessage)")

                    let screenshot = leakedView.makeScreenshot()

                    FloatViewManager.animateLeek(alloced: true)
                    PerformanceLeakDetector.shared.leaks.append(
                        .init(
                            details: errorMessage,
                            screenshot: screenshot,
                            id: Int(bitPattern: ObjectIdentifier(leakedView))
                        )
                    )

                    let deallocator = LVCDDeallocator()
                    deallocator.memoryLeakDetectionDate = Date().timeIntervalSince1970 - delay
                    deallocator.errorMessage = errorMessage
                    deallocator.objectIdentifier = Int(bitPattern: ObjectIdentifier(leakedView))
                    deallocator.objectType = "VIEW"
                    deallocator.subviews = leakedView.subviews
                    deallocator.weakView = leakedView
                    deallocator.screenshot = screenshot
                    objc_setAssociatedObject(
                        leakedView,
                        &LVCDDeallocator.key,
                        deallocator,
                        .OBJC_ASSOCIATION_RETAIN
                    )
                }
            }
        }
    }

    fileprivate func makeScreenshot() -> UIImage? {
        let fvc = firstViewController
        if let fvc, fvc.view == self {
            // UIImagePickerController is not available in tvOS so do OS check
            #if os(iOS)
            if fvc is UIImagePickerController {
                /// screenshotting UIIPC is not possible and can even lead to a permanent memory leak, PHPicker works fine though
                return nil
            }
            #endif
        }

        // create centered checkerboard background pattern image
        let squareSize: CGFloat = 20
        let offset = CGPoint(
            x: frame.width.truncatingRemainder(
                dividingBy: squareSize
            ) * 0.5,
            y: frame.height.truncatingRemainder(
                dividingBy: squareSize
            ) * 0.5
        )
        let checkerBoard = UIView(
            frame: .init(
                x: 0,
                y: 0,
                width: squareSize * 2,
                height: squareSize * 2
            )
        )
        checkerBoard.backgroundColor = .init(
            white: 1 - 0.4 * 0.5,
            alpha: 1
        )
        for point in [
            CGPoint(
                x: 0 as CGFloat,
                y: 0 as CGFloat
            ),
            CGPoint(
                x: -squareSize,
                y: squareSize
            ),
            CGPoint(
                x: squareSize,
                y: squareSize
            ),
            CGPoint(
                x: 0 as CGFloat,
                y: squareSize * 2
            )
        ] {
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = UIBezierPath(
                rect: .init(
                    x: point.x + offset.x,
                    y: point.y - offset.y,
                    width: squareSize,
                    height: squareSize
                )
            ).cgPath
            shapeLayer.fillColor = UIColor(
                white: 1 - 0.6 * 0.5,
                alpha: 1
            ).cgColor
            checkerBoard.layer.addSublayer(
                shapeLayer
            )
        }
        UIGraphicsBeginImageContextWithOptions(
            checkerBoard.bounds.size,
            false,
            0
        )
        checkerBoard.drawHierarchy(
            in: checkerBoard.bounds,
            afterScreenUpdates: true
        )
        let checkerBoardImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()

        let wasAlpha = alpha
        let wasHidden = isHidden
        alpha = alpha < 0.1 ? 1.0 : alpha // useful for alerts
        isHidden = false
        var wasTARMICS = [ObjectIdentifier: Bool]()
        var cornerRadius: CGFloat = 0

        // stick to two levels for now, seems to work best without constraint warnings
        // level 3 is necessary for getting UIAlert radius
        iterateSubviews(maxLevel: 3) { subview, level in
            if !(
                subview is UINavigationBar ||
                    subview is UICollectionViewCell ||
                    subview is UITabBar ||
                    subview is UIToolbar ||
                    level > 2
            ) {
                wasTARMICS[ObjectIdentifier(subview)] = subview.translatesAutoresizingMaskIntoConstraints
                subview.translatesAutoresizingMaskIntoConstraints = true
            }
            if
                cornerRadius == 0,
                subview.bounds == bounds,
                subview.layer.cornerRadius != 0 {
                cornerRadius = subview.layer.cornerRadius
            }

            return true
        }

        let container = UIView(
            frame: .init(
                origin: .zero,
                size: frame.size
            )
        )
        container.addSubview(self)
        objc_setAssociatedObject(
            container,
            &LVCDDeallocator.key,
            LVCDDeallocator(),
            .OBJC_ASSOCIATION_RETAIN
        ) // prevents triggering warnings itself

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = UIBezierPath(rect: frame).cgPath
        shapeLayer.fillColor = UIColor(patternImage: checkerBoardImage).withAlphaComponent(0.5).cgColor
        container.layer.insertSublayer(
            shapeLayer,
            at: 0
        )

        // check for subviews sticking out its bounds, forget about the same for sublayers for now
        var unclippedFrame = frame

        iterateSubviews {
            subview,
                _ in
            if subview.isHidden || subview.alpha < 0.1 {
                return false
            }

            var alpha: CGFloat = 0
            subview.backgroundColor?.getRed(
                nil,
                green: nil,
                blue: nil,
                alpha: &alpha
            )

            if subview.frame.size.height * subview.frame.size.width != 0,
               alpha >= 0.1 {
                unclippedFrame = unclippedFrame.union(
                    subview.convert(
                        subview.bounds,
                        to: container
                    )
                )
            }
            return !subview.clipsToBounds && !subview.layer.masksToBounds && !(
                subview is UIScrollView
            )
        }

        guard unclippedFrame.size.width > 0, unclippedFrame.size.height > 0 else {
            return nil
        }

        let container2 = UIView(
            frame: .init(
                origin: .zero,
                size: unclippedFrame.size
            )
        )
        container2.backgroundColor = UIColor.white.withAlphaComponent(
            0.03
        )
        container2.addSubview(
            container
        )
        container.frame = .init(
            x: 0 - unclippedFrame.minX,
            y: 0 - unclippedFrame.minY,
            width: unclippedFrame.width,
            height: unclippedFrame.height
        )
        container2.layer.cornerRadius = cornerRadius
        container2.layer.masksToBounds = container2.layer.cornerRadius > 0
        objc_setAssociatedObject(
            container2,
            &LVCDDeallocator.key,
            LVCDDeallocator(),
            .OBJC_ASSOCIATION_RETAIN
        ) // prevents triggering warnings itself

        let iosOnMac = ProcessInfo.processInfo.isMacCatalystApp
        let maxWidth: CGFloat = 240 - (
            iosOnMac ? 12 : 0
        ) // hard coded width for now
        let imageSize = container2.frame.width <= maxWidth ? container2.frame.size : CGSize(
            width: maxWidth,
            height: maxWidth * (
                container2.frame.height / container2.frame.width
            )
        )

        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
        container2.drawHierarchy(
            in: CGRect(
                x: 0,
                y: 0,
                width: imageSize.width,
                height: imageSize.height
            ),
            afterScreenUpdates: true
        )
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        // restore values just in case
        alpha = wasAlpha
        isHidden = wasHidden

        iterateSubviews {
            subview,
                level in
            if !(
                subview is UINavigationBar ||
                subview is UICollectionViewCell ||
                subview is UITabBar ||
                subview is UIToolbar ||
                level > 2
            ) {
                subview.translatesAutoresizingMaskIntoConstraints = wasTARMICS[ObjectIdentifier(
                    subview
                )] ?? subview.translatesAutoresizingMaskIntoConstraints
            }
            return true
        }

        return image
    }

    private func iterateTopSubviews(onViewFound: (UIView) -> Void) {
        var hasSubview = false

        if !(self is UINavigationBar && firstViewController is UINavigationController) {
            for subview in subviews {
                subview.iterateTopSubviews(onViewFound: onViewFound)
                hasSubview = true
            }
        }
        if !hasSubview {
            onViewFound(self)
        }
    }

    private func iterateSubviews(maxLevel: UInt = UInt.max, level: UInt = 0, onSubview: (UIView, UInt) -> (Bool)) {
        if onSubview(self, level) {
            let level = level + 1
            if level <= maxLevel {
                for subview in subviews {
                    subview.iterateSubviews(maxLevel: maxLevel, level: level, onSubview: onSubview)
                }
            }
        }
    }

    fileprivate var rootView: UIView {
        superview?.rootView ?? self
    }

    private var firstViewController: UIViewController? {
        sequence(first: self, next: { $0.next }).first(where: { $0 is UIViewController }) as? UIViewController
    }
}

extension UIViewController {
    enum Constants {
        fileprivate static let lvcdCheckForMemoryLeakNotification = Notification.Name("lvcdCheckForMemoryLeak")
        fileprivate static let lvcdCheckForSplitViewVCMemoryLeakNotification = Notification.Name("lvcdCheckForSplitViewVCMemoryLeak")
    }

    static func lvcdSwizzleLifecycleMethods() {
        lvcdActuallySwizzleLifecycleMethods // this makes sure it can only swizzle once
    }

    private static let lvcdActuallySwizzleLifecycleMethods: Void = {
        // Check if New Relic is present to avoid conflicts
        if NSClassFromString("NewRelic") != nil {
            print("⚠️ DebugSwift: New Relic detected - disabling leak detector to prevent conflicts")
            return
        }
        
        let originalVdaMethod = class_getInstanceMethod(
            UIViewController.self,
            #selector(viewDidLoad)
        )
        let swizzledVdaMethod = class_getInstanceMethod(
            UIViewController.self,
            #selector(lvcdViewDidLoad)
        )
        method_exchangeImplementations(
            originalVdaMethod!,
            swizzledVdaMethod!
        )

        let originalVddMethod = class_getInstanceMethod(
            UIViewController.self,
            #selector(viewDidDisappear(_:))
        )
        let swizzledVddMethod = class_getInstanceMethod(
            UIViewController.self,
            #selector(lvcdViewDidDisappear(_:))
        )
        method_exchangeImplementations(
            originalVddMethod!,
            swizzledVddMethod!
        )

        let originalRfpMethod = class_getInstanceMethod(
            UIViewController.self,
            #selector(removeFromParent)
        )
        let swizzledRfpMethod = class_getInstanceMethod(
            UIViewController.self,
            #selector(lvcdRemoveFromParent)
        )
        method_exchangeImplementations(
            originalRfpMethod!,
            swizzledRfpMethod!
        )

        let originalSdvcMethod = class_getInstanceMethod(
            UISplitViewController.self,
            #selector(showDetailViewController(_:sender:))
        )
        let swizzledSdvcMethod = class_getInstanceMethod(
            UIViewController.self,
            #selector(lvcdShowDetailViewController(_:sender:))
        )
        method_exchangeImplementations(
            originalSdvcMethod!,
            swizzledSdvcMethod!
        )

        let originalSvMethod = class_getInstanceMethod(
            UIViewController.self,
            #selector(setter: view)
        )
        let swizzledSvMethod = class_getInstanceMethod(
            UIViewController.self,
            #selector(lvcdSetView(_:))
        )
        method_exchangeImplementations(
            originalSvMethod!,
            swizzledSvMethod!
        )
    }()

    private func lvcdShouldIgnore() -> Bool {
        let ignoredVC = PerformanceLeakDetector.shared.ignoredViewControllerClassNames.contains(
            Self.description()
        )
        let ignoredWindow = isViewLoaded && view?.window != nil && PerformanceLeakDetector.shared.ignoredWindowClassNames.contains(type(of: view.window!).description())

        let ignoreLVCD = objc_getAssociatedObject(self, &LVCDSplitViewAssociatedObject.shared.key) != nil

        return ignoredVC || ignoredWindow || ignoreLVCD
    }

    @objc private func lvcdSetView(
        _ newView: UIView?
    ) {
        if isViewLoaded, let deallocator = objc_getAssociatedObject(self, &LVCDDeallocator.key) as? LVCDDeallocator {
            deallocator.strongView?.checkForLeakedSubViews()
            deallocator.strongView = newView
        }
        lvcdSetView(
            newView
        )
    }

    @objc private func lvcdViewDidLoad() {
        lvcdViewDidLoad() // run original implementation
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.1
        ) { [weak self] in
            guard let self else { return }
            if !self.lvcdShouldIgnore() {
                if objc_getAssociatedObject(
                    self,
                    &LVCDDeallocator.key
                ) == nil {
                    objc_setAssociatedObject(
                        self,
                        &LVCDDeallocator.key,
                        LVCDDeallocator(
                            self.view
                        ),
                        .OBJC_ASSOCIATION_RETAIN
                    )
                }
                self.addCheckForMemoryLeakObserver(
                    skipIgnoreCheck: true
                )
            }
        }
    }

    private func addCheckForMemoryLeakObserver(skipIgnoreCheck: Bool = false) {
        NotificationCenter.lvcd.removeObserver(
            self,
            name: UIViewController.Constants.lvcdCheckForMemoryLeakNotification,
            object: nil
        )
        if skipIgnoreCheck || !lvcdShouldIgnore() {
            NotificationCenter.lvcd.addObserver(
                self,
                selector: #selector(
                    lvcdCheckForMemoryLeak
                ),
                name: UIViewController.Constants.lvcdCheckForMemoryLeakNotification,
                object: nil
            )
        }
    }

    @objc private func lvcdViewDidDisappear(
        _ animated: Bool
    ) {
        lvcdViewDidDisappear(animated) // run original implementation

        // ignore parent VCs because one of their children will trigger viewDidDisappear() too
        if (self as? UINavigationController)?.viewControllers.isEmpty ?? true,
           (
               self as? UITabBarController
           )?.viewControllers?.isEmpty ?? true,
           (
               self as? UIPageViewController
           )?.viewControllers?.isEmpty ?? true,
           !lvcdShouldIgnore() {
            NotificationCenter.lvcd.post(
                name: Self.Constants.lvcdCheckForMemoryLeakNotification,
                object: nil
            )
        }
    }

    @objc private func lvcdRemoveFromParent() {
        lvcdRemoveFromParent() // run original implementation
        if !lvcdShouldIgnore(), view?.window != nil {
            NotificationCenter.lvcd.post(
                name: Self.Constants.lvcdCheckForMemoryLeakNotification,
                object: nil
            )
        }
    }

    @objc private func lvcdShowDetailViewController(
        _ vc: UIViewController,
        sender: Any?
    ) {
        NotificationCenter.lvcd.post(
            name: Self.Constants.lvcdCheckForSplitViewVCMemoryLeakNotification,
            object: self
        )
        NotificationCenter.lvcd.post(
            name: Self.Constants.lvcdCheckForMemoryLeakNotification,
            object: nil
        )

        if objc_getAssociatedObject(vc, &LVCDSplitViewAssociatedObject.shared.key) == nil {
            let mldAssociatedObject = LVCDSplitViewAssociatedObject.shared
            mldAssociatedObject.splitViewController = self as? UISplitViewController
            mldAssociatedObject.viewController = vc
            objc_setAssociatedObject(
                vc,
                &LVCDSplitViewAssociatedObject.shared.key,
                mldAssociatedObject,
                .OBJC_ASSOCIATION_RETAIN
            )
        }
        lvcdShowDetailViewController(
            vc,
            sender: sender
        ) // run original implementation
    }

    fileprivate static var lvcdMemoryCheckQueue = Set<ObjectIdentifier>()

    private var lvcdRootParentViewController: UIViewController {
        parent?.lvcdRootParentViewController ?? self
    }

    @objc private func lvcdCheckForMemoryLeak(
        restarted: Bool = false
    ) {
        // only check when active for now
        guard UIApplication.shared.applicationState == .active else { return }

        if (view != nil && view.window != nil) || lvcdShouldIgnore() {
            return
        }

        let objectIdentifier = ObjectIdentifier(self)

        // in some cases Constants.lvcdCheckForMemoryLeakNotification may be called multiple times at once, this guard prevents double checking
        guard !Self.lvcdMemoryCheckQueue.contains(
            objectIdentifier
        ) else {
            return
        }
        Self.lvcdMemoryCheckQueue.insert(
            objectIdentifier
        )

        DispatchQueue.main.async { [self] in
            Self.lvcdMemoryCheckQueue.remove(objectIdentifier)
            let rootParentVC = lvcdRootParentViewController
            guard
                rootParentVC.presentedViewController == nil,
                !isViewLoaded || rootParentVC.view.window == nil,
                let deallocator = objc_getAssociatedObject(self, &LVCDDeallocator.key) as? LVCDDeallocator,
                deallocator.objectIdentifier == 0
            else { return }

            if let svc = self as? UISplitViewController {
                NotificationCenter.lvcd.post(
                    name: Self.Constants.lvcdCheckForSplitViewVCMemoryLeakNotification,
                    object: svc
                )
            }

            let startTime = Date()

            let delay = PerformanceLeakDetector.shared.delay
            DispatchQueue.main.asyncAfter(
                deadline: .now() + delay
            ) { [weak self] in
                // if self is nil it deinitted, so no memory leak
                guard let self else { return }

                // if backgrounded now or during the delay ignore for now
                if UIApplication.shared.applicationState != .active || PerformanceLeakDetector.shared.lastBackgroundedDate > startTime {
                    return
                }

                // if somehow this asyncAfter code is executed way too late restart just in case
                if !restarted && abs(startTime.timeIntervalSinceNow) > delay + 0.5 {
                    self.lvcdCheckForMemoryLeak(restarted: true)
                    return
                }

                // these conditions constitute a 'limbo' ViewController, i.e. a memory leak:
                if
                    !self.isViewLoaded || self.view?.window == nil,
                    self.parent == nil, self.presentedViewController == nil,
                    self.view == nil || self.view.superview == nil || type(of: self.view.rootView).description() == "UILayoutContainerView" {
                    // once warned don't warn again
                    NotificationCenter.lvcd.removeObserver(
                        self,
                        name: Self.Constants.lvcdCheckForMemoryLeakNotification,
                        object: nil
                    )

                    let errorTitle = "VIEWCONTROLLER STILL IN MEMORY"
                    var errorMessage = self.debugDescription.lvcdRemoveBundleAndModuleName()

                    // add children's names to the message in case of NavVC or TabVC for easier identification
                    if let nvc = self as? UINavigationController {
                        errorMessage = "\(errorMessage):\n\(nvc.viewControllers)"
                    }
                    if let tbvc = self as? UITabBarController, let vcs = tbvc.viewControllers {
                        errorMessage = "\(errorMessage):\n\(vcs)"
                    }
                    // add alert title/message to the message for easier identification
                    if let alertVC = self as? UIAlertController {
                        var actions = alertVC.actions.isEmpty ? "-" : ""
                        for action in alertVC.actions {
                            actions = "\(actions) \"\(action.title ?? "-")\","
                        }

                        errorMessage = """
                            \(errorMessage)
                            title: \"\((alertVC.title ?? "") == "" ? "" : alertVC.title!)\"
                            message: \"\((alertVC.message ?? "") == "" ? "" : alertVC.message!)\"
                            actions: \(actions);
                        """

                        if alertVC.textFields?.isEmpty == false {
                            var tfs = ""
                            for tf in alertVC.textFields ?? [] {
                                tfs = "\(tfs) \"\(tf.placeholder ?? "-")\","
                            }
                            errorMessage += "\ntextfields: \(tfs);"
                        }

                        errorMessage = errorMessage.replacingOccurrences(
                            of: ",;",
                            with: ";"
                        )
                    }

                    PerformanceLeakDetector.shared.callback?(
                        .init(
                            controller: self,
                            message: "\(errorTitle) \(errorMessage)"
                        )
                    )
                    Debug.print("\(errorTitle) \(errorMessage)")

                    let screenshot = self.view?.rootView.makeScreenshot()
                    let id = Int(bitPattern: ObjectIdentifier(self))

                    if !PerformanceLeakDetector.shared.leaks.contains(where: { $0.id == id }) {
                        FloatViewManager.animateLeek(alloced: true)
                        PerformanceLeakDetector.shared.leaks.append(
                            .init(
                                details: errorMessage,
                                screenshot: screenshot,
                                id: id
                            )
                        )
                    }

                    deallocator.memoryLeakDetectionDate = Date().timeIntervalSince1970 - delay
                    deallocator.errorMessage = errorMessage
                    deallocator.objectIdentifier = Int(bitPattern: ObjectIdentifier(self))
                    deallocator.objectType = "VIEWCONTROLLER"
                    deallocator.screenshot = screenshot
                }
            }
        }
    }

    // Call this method if the ViewController deinitializes.
    // If a memory leak was detected earlier, this indicates that the leak has resolved itself.
    // Notify that the memory issue has been resolved
    fileprivate class func lvcdMemoryLeakResolved(
        memoryLeakDetectionDate: TimeInterval,
        errorMessage: String,
        objectIdentifier: Int,
        objectType: String,
        screenshot _: UIImage?
    ) {
        let interval = Date().timeIntervalSince1970 - memoryLeakDetectionDate

        FloatViewManager.animateLeek(alloced: false)
        let errorTitle = "LEAKED \(objectType) DEINNITED"
        let errorMessage = String(
            format: "\(errorMessage)\n\nDeinnited after %.3fs.",
            interval
        )

        if let index = PerformanceLeakDetector.shared.leaks.firstIndex(where: { $0.id == objectIdentifier }) {
            PerformanceLeakDetector.shared.leaks[index].hasDeallocated = true
            PerformanceLeakDetector.shared.leaks[index].timeAllocated = String(format: "%.3fs.", interval)
        }

        PerformanceLeakDetector.shared.callback?(
            .init(message: "\(errorTitle) \(errorMessage)")
        )

        Debug.print("\(errorTitle) \(errorMessage)")
    }

    fileprivate class LVCDSplitViewAssociatedObject: @unchecked Sendable {
        var key = malloc(1)!
        
        private init() {}
        static let shared = LVCDSplitViewAssociatedObject()

        weak var splitViewController: UISplitViewController?
        weak var viewController: UIViewController? { didSet {
            NotificationCenter.lvcd.addObserver(
                self,
                selector: #selector(checkIfBelongsToSplitViewController(_:)),
                name: UIViewController.Constants.lvcdCheckForSplitViewVCMemoryLeakNotification,
                object: nil
            )
        }}

       
    }
}

extension UIViewController {
    @objc func checkIfBelongsToSplitViewController(_ notification: Notification) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            guard
                let splitViewController = self.splitViewController,
                notification.object as? UISplitViewController == splitViewController,
                let vc = self.viewController
            else {
                return
            }

            // Remove associated object if any
            objc_setAssociatedObject(
                vc,
                &LVCDSplitViewAssociatedObject.shared.key,
                nil,
                .OBJC_ASSOCIATION_RETAIN
            )

            // Attach deallocator if not already present
            if objc_getAssociatedObject(vc, &LVCDDeallocator.key) == nil {
                objc_setAssociatedObject(
                    vc,
                    &LVCDDeallocator.key,
                    LVCDDeallocator(vc.view),
                    .OBJC_ASSOCIATION_RETAIN
                )
            }

            vc.addCheckForMemoryLeakObserver()

            // Delay logic inside same Task using async/await, no nested task
            try? await Task.sleep(nanoseconds: UInt64(PerformanceLeakDetector.shared.delay * 1_000_000_000))

            // Re-fetch `splitViewController` and `viewController` here
            if self.splitViewController == nil,
               let viewControllerAgain = self.viewController {
                viewControllerAgain.lvcdCheckForMemoryLeak()
            }
        }
    }
}

extension NotificationCenter {
    fileprivate static let lvcd = NotificationCenter()
}

private class LVCDDeallocator: @unchecked Sendable {
    nonisolated(unsafe) static var key = malloc(1)!

    var memoryLeakDetectionDate: TimeInterval = 0.0
    var errorMessage = ""
    var objectIdentifier = 0
    var objectType = ""
    var screenshot: UIImage?

    // used by ViewController
    var strongView: UIView?

    // used by View
    var subviews: [UIView]?
    var subviewObserver: NSKeyValueObservation?
    weak var weakView: UIView? { didSet {
        DispatchQueue.main.async {
            self.subviewObserver?.invalidate()
            self.subviewObserver = self.weakView?.layer.observe(\.sublayers, options: [.old, .new]) { [weak self] _, _ in
                if let view = self?.weakView {
                    DispatchQueue.main.async {
                        self?.subviews = view.subviews
                    }
                }
            }
        }
        // using observer allows to keep track of subviews during leak without themselves leaking
        // if leaked view clears it can then check its current subviews for leaks
    }}

    init(_ view: UIView? = nil) {
        self.strongView = view
    }

    deinit {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            // ViewController
            strongView?.checkForLeakedSubViews()
            strongView = nil // not needed, but just for peace of mind
            
            // View
            subviewObserver?.invalidate()
            for subview in subviews ?? [] {
                subview.checkForLeakedSubViews()
            }
        }

        if objectIdentifier != 0 {
            Task { [weak self] in
                let memoryLeakDetectionDate = self?.memoryLeakDetectionDate ?? 0
                let errorMessage = self?.errorMessage ?? ""
                let objectIdentifier = self?.objectIdentifier ?? 0
                let objectType = self?.objectType ?? ""
                let screenshot = self?.screenshot
                
                await UIViewController.lvcdMemoryLeakResolved(
                    memoryLeakDetectionDate: memoryLeakDetectionDate,
                    errorMessage: errorMessage,
                    objectIdentifier: objectIdentifier,
                    objectType: objectType,
                    screenshot: screenshot
                )
            }
        }
    }
}

extension UIResponder {
    fileprivate var viewController: UIViewController? {
        next as? UIViewController ?? next?.viewController
    }
}

extension UIApplication {
    /// get a window, preferably once that is in foreground (active) in case you have multiple windows on iPad
    private var lvcdActiveMainKeyWindow: UIWindow? {
        let activeScenes = connectedScenes.filter {
            $0.activationState == UIScene.ActivationState.foregroundActive
        }
        return (!activeScenes.isEmpty ? activeScenes : connectedScenes).flatMap {
            ($0 as? UIWindowScene)?.windows ?? []
        }.first(where: \.isKeyWindow)
    }

    private final class func lvcdTopViewController(
        controller: UIViewController? = UIApplication.shared.lvcdActiveMainKeyWindow?.rootViewController
    ) -> UIViewController? {
        controller?.presentedViewController != nil ? lvcdTopViewController(
            controller: controller!.presentedViewController!
        ) : controller
    }

    private final class func lvcdFindViewControllerWithTag(
        controller: UIViewController? = UIApplication.shared.lvcdActiveMainKeyWindow?.rootViewController,
        tag: Int
    ) -> UIViewController? {
        controller == nil ? nil : (
            controller!.view.tag == tag ? controller! : lvcdFindViewControllerWithTag(
                controller: controller!.presentedViewController,
                tag: tag
            )
        )
    }

    @available(iOS 13.0, tvOS 13, *)
    private var lvcdFirstActiveWindowScene: UIWindowScene? {
        let activeScenes = UIApplication.shared.connectedScenes.filter {
            $0.activationState == UIScene.ActivationState.foregroundActive && $0 is UIWindowScene
        }
        return (!activeScenes.isEmpty ? activeScenes : UIApplication.shared.connectedScenes).first(where: {
            $0 is UIWindowScene
        }) as? UIWindowScene
    }
}

extension String {
    private mutating func lvcdRegReplace(
        pattern: String,
        replaceWith: String = ""
    ) {
        do {
            let regex = try NSRegularExpression(
                pattern: pattern,
                options: [
                    .caseInsensitive,
                    .anchorsMatchLines
                ]
            )
            let range = NSRange(
                startIndex...,
                in: self
            )
            self = regex.stringByReplacingMatches(
                in: self,
                options: [],
                range: range,
                withTemplate: replaceWith
            )
        } catch {
            return
        }
    }

    enum Constants {
        nonisolated(unsafe) static var lvcdBundleName: String?
        nonisolated(unsafe) static var lvcdModuleName: String?
    }

    fileprivate func lvcdRemoveBundleAndModuleName() -> String {
        Constants.lvcdBundleName = Constants.lvcdBundleName ?? Bundle.main.infoDictionary?["CFBundleName"] as? String
        if Constants.lvcdBundleName != nil, Constants.lvcdModuleName == nil {
            Constants.lvcdModuleName = Constants.lvcdBundleName
            Constants.lvcdModuleName?.lvcdRegReplace(
                pattern: "[^A-Za-z0-9]",
                replaceWith: "_"
            )
        }
        if Constants.lvcdBundleName != nil, Constants.lvcdModuleName != nil {
            return replacingOccurrences(
                of: "\(Constants.lvcdBundleName!).",
                with: ""
            ).replacingOccurrences(
                of: "\(Constants.lvcdModuleName!).",
                with: ""
            )
        }
        return self
    }
}

extension PerformanceLeakDetector {
    struct LeakModel {
        let details: String
        let screenshot: UIImage?
        let id: Int

        var hasDeallocated = false
        var timeAllocated: String?

        var isActive: Bool { !hasDeallocated }
        var symbol: String { hasDeallocated ? "✳️" : "⚠️" }
    }
}
