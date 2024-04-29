//
//  Performance.Toolkit.swift
//  DebugSwift
//
//  Created by Matheus Gois on 15/12/23.
//  Copyright © 2023 apple. All rights reserved.
//

import Foundation
import UIKit

final class PerformanceToolkit {
    let widget: PerformanceWidgetView
    var measurementsTimer: Timer?
    var fpsCounter = FPSCounter()
    var cpuMeasurements: [CGFloat] = []
    var currentCPU: CGFloat = 0
    var maxCPU: CGFloat = 0
    var memoryMeasurements: [CGFloat] = []
    var currentMemory: CGFloat = 0
    var maxMemory: CGFloat = 0
    var fpsMeasurements: [CGFloat] = []

    var currentFPS: CGFloat = 0
    var minFPS: CGFloat = 9999
    var maxFPS: CGFloat = 0

    var currentMeasurementIndex = 0
    let measurementsLimit = 120
    var timeBetweenMeasurements: TimeInterval = 1
    var controllerMarked: TimeInterval = 20

    weak var delegate: PerformanceToolkitDelegate?

    var isWidgetShown: Bool {
        get {
            !widget.isHidden
        }
        set {
            widget.toggle(with: newValue)
        }
    }

    init(widgetDelegate: PerformanceWidgetViewDelegate) {
        self.widget = PerformanceWidgetView()
        widget.alpha = 0.0
        widget.isHidden = true
        widget.delegate = widgetDelegate

        setupPerformanceMeasurement()
        fpsCounter.startTracking()
    }

    deinit {
        measurementsTimer?.invalidate()
        measurementsTimer = nil
        fpsCounter.stopTracking()
    }

    func setupPerformanceMeasurement() {
        measurementsTimer = Timer(
            timeInterval: 1.0, target: self, selector: #selector(updateMeasurements), userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(measurementsTimer!, forMode: .common)

        // Additional setup for measurements
        cpuMeasurements = Array(repeating: 0, count: measurementsLimit)
        memoryMeasurements = Array(repeating: 0, count: measurementsLimit)
        fpsMeasurements = Array(repeating: 0, count: measurementsLimit)
    }

    @objc private func updateMeasurements() {
        // Update CPU measurements
        currentCPU = cpu()
        cpuMeasurements = array(cpuMeasurements, byAddingMeasurement: currentCPU)
        maxCPU = max(maxCPU, currentCPU)

        // Update memory measurements
        currentMemory = memory()
        memoryMeasurements = array(memoryMeasurements, byAddingMeasurement: currentMemory)
        maxMemory = max(maxMemory, currentMemory)

        // Update FPS measurements
        currentFPS = fps()
        fpsMeasurements = array(fpsMeasurements, byAddingMeasurement: currentFPS)
        if !currentFPS.isZero {
            minFPS = min(minFPS, currentFPS)
        }
        maxFPS = max(maxFPS, currentFPS)

        DispatchQueue.main.async {
            self.refreshWidget()
        }
        delegate?.performanceToolkitDidUpdateStats(self)
        currentMeasurementIndex = min(measurementsLimit, currentMeasurementIndex + 1)
    }

    private func array<T>(_ array: [T], byAddingMeasurement measurement: T) -> [T] {
        var newMeasurements = array

        if currentMeasurementIndex == measurementsLimit {
            // Shift previous measurements
            for index in 0..<measurementsLimit - 1 {
                newMeasurements[index] = newMeasurements[index + 1]
            }

            // Add the new measurement to the end of the array
            newMeasurements[measurementsLimit - 1] = measurement
        } else {
            // Add the next measurement if we haven't reached the limit
            newMeasurements.append(measurement)
        }

        return newMeasurements
    }

    private func refreshWidget() {
        widget.updateValues(cpu: currentCPU, memory: currentMemory, fps: currentFPS)
    }

    func cpu() -> CGFloat {
        var totalUsageOfCPU: CGFloat = 0.0
        var threadsList = UnsafeMutablePointer(mutating: [thread_act_t]())
        var threadsCount = mach_msg_type_number_t(0)
        let threadsResult = withUnsafeMutablePointer(to: &threadsList) {
            $0.withMemoryRebound(to: thread_act_array_t?.self, capacity: 1) {
                task_threads(mach_task_self_, $0, &threadsCount)
            }
        }

        if threadsResult == KERN_SUCCESS {
            for index in 0..<threadsCount {
                var threadInfo = thread_basic_info()
                var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
                let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        thread_info(
                            threadsList[Int(index)], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount
                        )
                    }
                }

                guard infoResult == KERN_SUCCESS else {
                    break
                }

                let threadBasicInfo = threadInfo as thread_basic_info
                if threadBasicInfo.flags & TH_FLAGS_IDLE == 0 {
                    totalUsageOfCPU =
                        (totalUsageOfCPU + (Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0))
                }
            }
        }

        vm_deallocate(
            mach_task_self_, vm_address_t(UInt(bitPattern: threadsList)),
            vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride)
        )
        return totalUsageOfCPU
    }

    private func memory() -> CGFloat {
        var taskInfo = task_basic_info()
        var count = mach_msg_type_number_t(
            MemoryLayout.size(ofValue: taskInfo) / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), $0, &count)
            }
        }

        return result == KERN_SUCCESS ? CGFloat(taskInfo.resident_size) / 1024.0 / 1024.0 : 0
    }

    func simulateMemoryWarning() {
        let keyData = Data([
            0x5f, 0x70, 0x65, 0x72, 0x66, 0x6f, 0x72, 0x6d, 0x4d, 0x65, 0x6d, 0x6f, 0x72, 0x79, 0x57,
            0x61, 0x72, 0x6e, 0x69, 0x6e, 0x67
        ])
        let key = String(data: keyData, encoding: .ascii)!
        let selector = NSSelectorFromString(key)
        let object = UIApplication.shared
        if object.responds(to: selector) {
            _ = object.perform(selector)
        }
    }

    private func fps() -> CGFloat {
        fpsCounter.fps
    }
}

protocol PerformanceToolkitDelegate: AnyObject {
    func performanceToolkitDidUpdateStats(_ toolkit: PerformanceToolkit)
}
