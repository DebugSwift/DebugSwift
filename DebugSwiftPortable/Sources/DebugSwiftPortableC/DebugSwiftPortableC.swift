import DebugSwiftPortable
import Foundation

@_cdecl("debugswift_record_event")
public func debugswift_record_event(
    _ categoryPointer: UnsafePointer<CChar>?,
    _ messagePointer: UnsafePointer<CChar>?
) {
    let category = categoryPointer.map { String(cString: $0) } ?? "android"
    let message = messagePointer.map { String(cString: $0) } ?? ""
    DebugSwiftCore.shared.record(
        DebugEvent(level: .info, category: category, message: message)
    )
}

@_cdecl("debugswift_snapshot_json")
public func debugswift_snapshot_json(
    _ appNamePointer: UnsafePointer<CChar>?,
    _ platformPointer: UnsafePointer<CChar>?
) -> UnsafeMutablePointer<CChar>? {
    let appName = appNamePointer.map { String(cString: $0) } ?? "Unknown"
    let platform = platformPointer.map { String(cString: $0) } ?? "Android"
    let snapshot = DebugSwiftCore.shared.snapshot(appName: appName, platform: platform)
    let json = (try? snapshot.jsonString()) ?? #"{"error":"snapshot_encoding_failed"}"#
    return strdup(json)
}

@_cdecl("debugswift_free_string")
public func debugswift_free_string(_ pointer: UnsafeMutablePointer<CChar>?) {
    free(pointer)
}

@_cdecl("debugswift_reset")
public func debugswift_reset() {
    DebugSwiftCore.shared.reset()
}
