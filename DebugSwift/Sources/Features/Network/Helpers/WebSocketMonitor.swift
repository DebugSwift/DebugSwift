//
//  WebSocketMonitor.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import Foundation
import Network

enum WebSocketMonitorError: LocalizedError {
    case connectionNotTracked
    case taskNotRunning

    var errorDescription: String? {
        switch self {
        case .connectionNotTracked:
            return "Unable to find an active WebSocket task for this connection."
        case .taskNotRunning:
            return "The WebSocket task is not running."
        }
    }
}

final class WebSocketMonitor: NSObject, @unchecked Sendable {
    static let shared = WebSocketMonitor()
    
    private var _isEnabled = false
    private var trackedTasks: [URLSessionWebSocketTask: String] = [:]
    private let monitorQueue = DispatchQueue(label: "WebSocketMonitor", qos: .utility)
    private var isSwizzled = false
    
    var isEnabled: Bool {
        get { monitorQueue.sync { _isEnabled } }
        set { monitorQueue.sync { _isEnabled = newValue } }
    }
    
    private override init() {
        super.init()
        setupNotifications()
    }
    
    // MARK: - Public API
    
    func enable() {
        guard !isEnabled else { return }
        isEnabled = true
        performMethodSwizzling()
        Debug.print("WebSocket monitoring enabled with method swizzling")
    }
    
    func disable() {
        guard isEnabled else { return }
        isEnabled = false
        Debug.print("WebSocket monitoring disabled")
    }
    
    // MARK: - Method Swizzling
    
    private func performMethodSwizzling() {
        guard !isSwizzled else { return }
        
        guard let websocketClass = NSClassFromString("__NSURLSessionWebSocketTask") else {
            Debug.print("[WebSocketMonitor][ERROR] Could not find __NSURLSessionWebSocketTask class")
            return
        }
        
        swizzleSendMessage(in: websocketClass)
        swizzleReceiveMessage(in: websocketClass)
        swizzleSendPing(in: websocketClass)
        swizzleCancelWithCloseCode(in: websocketClass)
        swizzleResume(in: websocketClass)
        
        isSwizzled = true
        Debug.print("WebSocket method swizzling completed")
    }
    
    private func swizzleSendMessage(in wsClass: AnyClass) {
        let selector = NSSelectorFromString("sendMessage:completionHandler:")
        guard let method = class_getInstanceMethod(wsClass, selector),
              wsClass.instancesRespond(to: selector) else {
            Debug.print("Could not swizzle sendMessage:completionHandler:")
            return
        }
        
        typealias SendMessageType = @convention(c) (AnyObject, Selector, AnyObject, AnyObject) -> Void
        let originalImp: IMP = method_getImplementation(method)
        
        let block: @convention(block) (AnyObject, AnyObject, AnyObject) -> Void = { [weak self] (task, message, completion) in
            // Call original implementation
            let original: SendMessageType = unsafeBitCast(originalImp, to: SendMessageType.self)
            original(task, selector, message, completion)
            
            // Handle our monitoring
            if let self = self, self.isEnabled,
               let websocketTask = task as? URLSessionWebSocketTask,
               let swiftMessage = self.convertToSwiftMessage(from: message) {
                Task { @MainActor in
                    self.handleSentMessage(task: websocketTask, message: swiftMessage)
                }
            }
        }
        
        method_setImplementation(method, imp_implementationWithBlock(block))
    }
    
    private func swizzleReceiveMessage(in wsClass: AnyClass) {
        let sel = NSSelectorFromString("receiveMessageWithCompletionHandler:")
        guard let method = class_getInstanceMethod(wsClass, sel) else {
            Debug.print("⚠️ Couldn’t find receiveMessageWithCompletionHandler:")
            return
        }

        // 1) Grab the original IMP
        let originalImp = method_getImplementation(method)

        // 2) Define the real ObjC-block signature for the handler:
        //    (NSURLSessionWebSocketMessage * _Nullable, NSError * _Nullable) -> Void
        typealias HandlerBlock = @convention(block) (AnyObject?, NSError?) -> Void

        // 3) And our replacement block takes (self, handlerAsAnyObject)
        let swizzleBlock: @convention(block) (AnyObject, AnyObject) -> Void = { [weak self] obj, rawHandler in
            // Cast the raw handler to the concrete block type:
            let originalHandler = unsafeBitCast(rawHandler, to: HandlerBlock.self)

            // Wrap it so we can intercept the incoming message/error
            let wrapped: HandlerBlock = { messageObj, error in
                if let self = self,
                   let task = obj as? URLSessionWebSocketTask {
                    if let err = error {
                        Task { @MainActor in self.handleReceiveError(task: task, error: err) }
                    } else if let msgObj = messageObj,
                              let msg = self.convertToSwiftMessage(from: msgObj) {
                        Task { @MainActor in self.handleReceivedMessage(task: task, message: msg) }
                    }
                }
                // Forward to the original handler
                originalHandler(messageObj, error)
            }

            // Invoke the original IMP
            typealias OrigC = @convention(c) (AnyObject, Selector, HandlerBlock) -> Void
            let fn = unsafeBitCast(originalImp, to: OrigC.self)
            fn(obj, sel, wrapped)
        }

        // 4) **Crucial**: box that @convention(block) into AnyObject so imp_implementationWithBlock sees a concrete type
        let blockObj = unsafeBitCast(swizzleBlock, to: AnyObject.self)
        let newImp = imp_implementationWithBlock(blockObj)

        // 5) Swap it in
        method_setImplementation(method, newImp)
        Debug.print("✅ Swizzled receiveMessageWithCompletionHandler:")
    }

    
    private func swizzleSendPing(in wsClass: AnyClass) {
        let selector = NSSelectorFromString("sendPingWithPongReceiveHandler:")
        guard let method = class_getInstanceMethod(wsClass, selector),
              wsClass.instancesRespond(to: selector) else {
            Debug.print("Could not swizzle sendPingWithPongReceiveHandler:")
            return
        }
        
        typealias SendPingType = @convention(c) (AnyObject, Selector, AnyObject) -> Void
        let originalImp: IMP = method_getImplementation(method)
        
        let block: @convention(block) (AnyObject, AnyObject) -> Void = { [weak self] (task, handler) in
            // Call original implementation
            let original: SendPingType = unsafeBitCast(originalImp, to: SendPingType.self)
            original(task, selector, handler)
            
            // Handle our monitoring
            if let self = self, self.isEnabled,
               let websocketTask = task as? URLSessionWebSocketTask {
                Task { @MainActor in
                    self.handlePingSent(task: websocketTask)
                }
            }
        }
        
        method_setImplementation(method, imp_implementationWithBlock(block))
    }
    
    private func swizzleCancelWithCloseCode(in wsClass: AnyClass) {
        let selector = NSSelectorFromString("cancelWithCloseCode:reason:")
        guard let method = class_getInstanceMethod(wsClass, selector),
              wsClass.instancesRespond(to: selector) else {
            Debug.print("Could not swizzle cancelWithCloseCode:reason:")
            return
        }
        
        typealias CancelType = @convention(c) (AnyObject, Selector, NSInteger, AnyObject?) -> Void
        let originalImp: IMP = method_getImplementation(method)
        
        let block: @convention(block) (AnyObject, NSInteger, AnyObject?) -> Void = { [weak self] (task, closeCode, reason) in
            // Handle our monitoring before calling original
            if let self = self, self.isEnabled,
               let websocketTask = task as? URLSessionWebSocketTask {
                let code = URLSessionWebSocketTask.CloseCode(rawValue: closeCode) ?? .invalid
                let reasonData = reason as? Data
                Task { @MainActor in
                    self.handleConnectionClosed(task: websocketTask, closeCode: code, reason: reasonData)
                }
            }
            
            // Call original implementation
            let original: CancelType = unsafeBitCast(originalImp, to: CancelType.self)
            original(task, selector, closeCode, reason)
        }
        
        method_setImplementation(method, imp_implementationWithBlock(block))
    }
    
    private func swizzleResume(in wsClass: AnyClass) {
        let selector = NSSelectorFromString("resume")
        guard let method = class_getInstanceMethod(wsClass, selector),
              wsClass.instancesRespond(to: selector) else {
            Debug.print("Could not swizzle resume")
            return
        }
        
        typealias ResumeType = @convention(c) (AnyObject, Selector) -> Void
        let originalImp: IMP = method_getImplementation(method)
        
        let block: @convention(block) (AnyObject) -> Void = { [weak self] (task) in
            // Call original implementation first
            let original: ResumeType = unsafeBitCast(originalImp, to: ResumeType.self)
            original(task, selector)
            
            // Handle our monitoring
            if let self = self, self.isEnabled,
               let websocketTask = task as? URLSessionWebSocketTask {
                Task { @MainActor in
                    self.handleConnectionStarted(task: websocketTask)
                }
            }
        }
        
        method_setImplementation(method, imp_implementationWithBlock(block))
    }
    
    // MARK: - Message Conversion
    
    private func convertToSwiftMessage(from anyMessage: AnyObject) -> URLSessionWebSocketTask.Message? {
        // More robust extraction following Atlantis pattern
        
        // First try direct property access (safer)
        if let stringValue = anyMessage.value(forKey: "string") as? String {
            return .string(stringValue)
        }
        
        if let dataValue = anyMessage.value(forKey: "data") as? Data {
            return .data(dataValue)
        }
        
        // Fallback: Try to determine type from object description (less reliable)
        let description = String(describing: anyMessage)
        if description.contains("string:") {
            // Try to extract string from description if KVC fails
            Debug.print("WebSocket: Failed to extract string via KVC, falling back")
        } else if description.contains("data:") {
            Debug.print("WebSocket: Failed to extract data via KVC, falling back")
        }
        
        return nil
    }
    
    private func createWrappedReceiveHandler(originalHandler: AnyObject, task: URLSessionWebSocketTask?) -> AnyObject {
        // Define the completion handler type that matches URLSessionWebSocketTask.receive
        typealias WebSocketReceiveHandler = @convention(block) (AnyObject?, NSError?) -> Void
        
        let wrappedHandler: WebSocketReceiveHandler = { [weak self] (message, error) in
            // Handle our monitoring first
            if let self = self, self.isEnabled, let task = task {
                if let error = error {
                    Task { @MainActor in
                        self.handleReceiveError(task: task, error: error)
                    }
                } else if let message = message,
                          let swiftMessage = self.convertToSwiftMessage(from: message) {
                    Task { @MainActor in
                        self.handleReceivedMessage(task: task, message: swiftMessage)
                    }
                }
            }
            
            // Call the original handler
            if let originalBlock = originalHandler as? WebSocketReceiveHandler {
                originalBlock(message, error)
            }
        }
        
        return wrappedHandler as AnyObject
    }
    
    // MARK: - Event Handlers
    
    @MainActor
    private func handleConnectionStarted(task: URLSessionWebSocketTask) {
        let connectionId = getOrCreateConnectionId(for: task)
        
        // Connection is already in .connecting status by default
        Debug.print("WebSocket connection started for: \(task.currentRequest?.url?.absoluteString ?? "unknown")")
        
        // Set a timeout to mark connection as failed if no activity within 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            if let connection = WebSocketDataSource.shared.getConnection(withId: connectionId),
               connection.status == .connecting {
                let timeoutError = NSError(
                    domain: "WebSocketMonitor",
                    code: -1001,
                    userInfo: [NSLocalizedDescriptionKey: "Connection timeout"]
                )
                WebSocketDataSource.shared.updateConnectionStatus(connectionId, status: .error(timeoutError))
                Debug.print("WebSocket connection timed out for: \(task.currentRequest?.url?.absoluteString ?? "unknown")")
            }
        }
        
        // Also try to update to connected after a brief delay if task is running
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if let connection = WebSocketDataSource.shared.getConnection(withId: connectionId),
               connection.status == .connecting,
               task.state == .running {
                WebSocketDataSource.shared.updateConnectionStatus(connectionId, status: .connected)
                Debug.print("WebSocket connection established for: \(task.currentRequest?.url?.absoluteString ?? "unknown")")
            }
        }
    }
    
    @MainActor
    private func handleSentMessage(task: URLSessionWebSocketTask, message: URLSessionWebSocketTask.Message) {
        let connectionId = getOrCreateConnectionId(for: task)
        
        // Update connection status to connected if we can successfully send a message
        if let connection = WebSocketDataSource.shared.getConnection(withId: connectionId),
           connection.status == .connecting {
            WebSocketDataSource.shared.updateConnectionStatus(connectionId, status: .connected)
        }
        
        let (frameType, payload) = extractFrameData(from: message)
        let frame = WebSocketFrame(
            direction: .sent,
            type: frameType,
            payload: payload,
            connectionId: connectionId
        )
        
        WebSocketDataSource.shared.addFrame(frame)
        Debug.print("WebSocket sent message: \(frameType)")
    }
    
    @MainActor
    private func handleReceivedMessage(task: URLSessionWebSocketTask, message: URLSessionWebSocketTask.Message) {
        let connectionId = getOrCreateConnectionId(for: task)
        
        // Update connection status to connected on first successful frame
        if let connection = WebSocketDataSource.shared.getConnection(withId: connectionId),
           connection.status == .connecting {
            WebSocketDataSource.shared.updateConnectionStatus(connectionId, status: .connected)
        }
        
        let (frameType, payload) = extractFrameData(from: message)
        let frame = WebSocketFrame(
            direction: .received,
            type: frameType,
            payload: payload,
            connectionId: connectionId
        )
        
        WebSocketDataSource.shared.addFrame(frame)
        
        // Notify UI to refresh
        NotificationCenter.default.post(
            name: NSNotification.Name("reloadWebSocket_DebugSwift"),
            object: nil
        )
        
        Debug.print("WebSocket received message: \(frameType)")
    }
    
    @MainActor
    private func handlePingSent(task: URLSessionWebSocketTask) {
        let connectionId = getOrCreateConnectionId(for: task)
        
        let frame = WebSocketFrame(
            direction: .sent,
            type: .ping,
            payload: "ping".data(using: .utf8) ?? Data(),
            connectionId: connectionId
        )
        
        WebSocketDataSource.shared.addFrame(frame)
        Debug.print("WebSocket sent ping")
    }
    
    @MainActor
    private func handleReceiveError(task: URLSessionWebSocketTask, error: Error) {
        let connectionId = getOrCreateConnectionId(for: task)
        WebSocketDataSource.shared.updateConnectionStatus(connectionId, status: .error(error))
        
        // Notify UI to refresh
        NotificationCenter.default.post(
            name: NSNotification.Name("reloadWebSocket_DebugSwift"),
            object: nil
        )
        
        Debug.print("WebSocket receive error: \(error.localizedDescription)")
    }
    
    @MainActor
    private func handleConnectionClosed(task: URLSessionWebSocketTask, closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        let connectionId = getOrCreateConnectionId(for: task)
        
        // Add close frame
        let reasonString = reason?.string(encoding: .utf8) ?? ""
        let closeMessage = "Close Code: \(closeCode.rawValue), Reason: \(reasonString)"
        let frame = WebSocketFrame(
            direction: .sent,
            type: .close,
            payload: closeMessage.data(using: .utf8) ?? Data(),
            connectionId: connectionId
        )
        
        WebSocketDataSource.shared.addFrame(frame)
        WebSocketDataSource.shared.updateConnectionStatus(connectionId, status: .closed)
        
        // Remove from tracked tasks
        trackedTasks.removeValue(forKey: task)
        
        // Notify UI to refresh
        NotificationCenter.default.post(
            name: NSNotification.Name("reloadWebSocket_DebugSwift"),
            object: nil
        )
        
        Debug.print("WebSocket connection closed with code: \(closeCode.rawValue)")
    }
    
    // MARK: - Connection Management
    
    @MainActor
    private func getOrCreateConnectionId(for task: URLSessionWebSocketTask) -> String {
        if let existingId = trackedTasks[task] {
            return existingId
        }
        
        // Create new connection
        let url = task.currentRequest?.url ?? URL(string: "ws://unknown")!
        let connection = WebSocketConnection(url: url)
        
        WebSocketDataSource.shared.addConnection(connection)
        trackedTasks[task] = connection.id
        
        // Notify UI about new connection
        NotificationCenter.default.post(
            name: NSNotification.Name("reloadWebSocket_DebugSwift"),
            object: nil
        )
        
        Debug.print("Created new WebSocket connection: \(url.absoluteString)")
        return connection.id
    }
    
    // MARK: - Manual Registration (Fallback)
    
    @MainActor
    func trackConnection(_ task: URLSessionWebSocketTask, url: URL, channelName: String? = nil) {
        let connection = WebSocketConnection(url: url, channelName: channelName)
        WebSocketDataSource.shared.addConnection(connection)
        trackedTasks[task] = connection.id
        
        // Notify UI about new connection
        NotificationCenter.default.post(
            name: NSNotification.Name("reloadWebSocket_DebugSwift"),
            object: nil
        )
        
        Debug.print("Manually tracked WebSocket connection: \(url.absoluteString)")
    }
    
    func extractFrameData(from message: URLSessionWebSocketTask.Message) -> (WebSocketFrameType, Data) {
        switch message {
        case .string(let text):
            return (.text, text.data(using: .utf8) ?? Data())
        case .data(let data):
            return (.binary, data)
        @unknown default:
            return (.binary, Data())
        }
    }
    
    func getConnectionId(for task: URLSessionWebSocketTask) -> String? {
        return trackedTasks[task]
    }
    
    func removeTask(_ task: URLSessionWebSocketTask) {
        trackedTasks.removeValue(forKey: task)
    }

    @MainActor
    func sendMessage(
        _ message: URLSessionWebSocketTask.Message,
        onConnectionId connectionId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let task = trackedTasks.first(where: { $0.value == connectionId })?.key else {
            completion(.failure(WebSocketMonitorError.connectionNotTracked))
            return
        }

        guard task.state == .running else {
            completion(.failure(WebSocketMonitorError.taskNotRunning))
            return
        }

        task.send(message) { error in
            DispatchQueue.main.async {
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("closeWebSocket_DebugSwift"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let connectionId = notification.object as? String else { return }
            self?.forceCloseConnection(connectionId: connectionId)
        }
    }
    
    private func forceCloseConnection(connectionId: String) {
        Task { @MainActor in
            // Find and close the WebSocket task
            for (task, taskConnectionId) in trackedTasks where taskConnectionId == connectionId {
                task.cancel(with: .goingAway, reason: "Closed by DebugSwift".data(using: .utf8))
                trackedTasks.removeValue(forKey: task)
                break
            }
        }
    }
}

// MARK: - Data Extensions

private extension Data {
    func string(encoding: String.Encoding) -> String? {
        return String(data: self, encoding: encoding)
    }
}
