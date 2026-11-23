import Darwin
import Foundation

@MainActor
struct PerformanceMemoryMonitor {
    private typealias Configuration = DebugSwift.Performance.Memory

    private var revision = Configuration.revision
    private(set) var metric = DebugSwift.Performance.Memory.metric
    private(set) var current: CGFloat?
    private(set) var peak: CGFloat?
    private(set) var history: [CGFloat] = []

    mutating func update(
        limit: Int,
        sample: (DebugSwift.Performance.Memory.Metric) -> CGFloat? = Self.sample
    ) {
        if revision != Configuration.revision {
            revision = Configuration.revision
            metric = Configuration.metric
            history.removeAll(keepingCapacity: true)
            peak = nil
        }

        current = sample(metric)
        guard let current else { return }

        history.append(current)
        if history.count > limit {
            history.removeFirst()
        }
        peak = max(peak ?? current, current)
    }

    nonisolated private static func sample(_ metric: DebugSwift.Performance.Memory.Metric) -> CGFloat? {
        switch metric {
        case .rss:
            return read(task_basic_info(), flavor: TASK_BASIC_INFO, field: \.resident_size)
        case .physFootprint:
            return read(task_vm_info_data_t(), flavor: TASK_VM_INFO, field: \.phys_footprint)
        }
    }

    nonisolated private static func read<Info, Bytes: BinaryInteger>(
        _ initialInfo: Info,
        flavor: Int32,
        field: KeyPath<Info, Bytes>
    ) -> CGFloat? {
        var info = initialInfo
        let wordSize = MemoryLayout<integer_t>.size
        let capacity = MemoryLayout<Info>.size / wordSize
        var count = mach_msg_type_number_t(capacity)

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: capacity) {
                task_info(mach_task_self_, task_flavor_t(flavor), $0, &count)
            }
        }

        // Older kernels may return a shorter revision of TASK_VM_INFO.
        guard result == KERN_SUCCESS,
              let offset = MemoryLayout<Info>.offset(of: field),
              Int(count) * wordSize >= offset + MemoryLayout<Bytes>.size
        else { return nil }

        return CGFloat(info[keyPath: field]) / 1024 / 1024
    }
}
