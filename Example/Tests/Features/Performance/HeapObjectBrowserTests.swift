//
//  HeapObjectBrowserTests.swift
//  DebugSwift
//
//  Created by Claude Code on 16/08/25.
//

import XCTest
@testable import DebugSwift

final class HeapObjectBrowserTests: XCTestCase {
    
    var heapBrowser: HeapObjectBrowser!
    
    override func setUp() {
        super.setUp()
        heapBrowser = HeapObjectBrowser()
    }
    
    override func tearDown() {
        heapBrowser = nil
        super.tearDown()
    }
    
    // MARK: - Heap Scanning Tests
    
    func testScanHeapReturnsClasses() {
        // Given: A heap browser
        
        // When: Scanning the heap for objects
        let classes = heapBrowser.scanHeapForClasses()
        
        // Then: Should return a non-empty array of class info
        XCTAssertFalse(classes.isEmpty, "Heap scan should return at least some classes")
        XCTAssertTrue(classes.allSatisfy { $0.instanceCount > 0 }, "All classes should have positive instance count")
    }
    
    func testScanHeapIncludesNSObjectSubclasses() {
        // Given: A heap browser
        
        // When: Scanning the heap
        let classes = heapBrowser.scanHeapForClasses()
        
        // Then: Should include NSObject-based classes
        let classNames = classes.map { $0.className }
        XCTAssertTrue(classNames.contains("NSObject") || 
                      classNames.contains(where: { $0.contains("String") }),
                      "Should include basic Objective-C/Swift classes")
    }
    
    func testClassInfoHasRequiredProperties() {
        // Given: A heap browser
        
        // When: Scanning for classes
        let classes = heapBrowser.scanHeapForClasses()
        
        // Then: Each class info should have required properties
        for classInfo in classes.prefix(5) { // Test first 5 to avoid long test times
            XCTAssertFalse(classInfo.className.isEmpty, "Class name should not be empty")
            XCTAssertGreaterThan(classInfo.instanceCount, 0, "Instance count should be positive")
            XCTAssertGreaterThanOrEqual(classInfo.memoryFootprint, 0, "Memory footprint should be non-negative")
        }
    }
    
    // MARK: - Filtering Tests
    
    func testFilterClassesByName() {
        // Given: A heap browser with some classes
        let allClasses = heapBrowser.scanHeapForClasses()
        
        // When: Filtering by a common substring
        let filtered = heapBrowser.filterClasses(allClasses, searchText: "NS")
        
        // Then: Should return only matching classes
        XCTAssertTrue(filtered.allSatisfy { $0.className.contains("NS") },
                      "All filtered classes should contain 'NS'")
        XCTAssertLessThanOrEqual(filtered.count, allClasses.count,
                                "Filtered results should not exceed total")
    }
    
    func testFilterClassesEmptySearchReturnsAll() {
        // Given: A heap browser with classes
        let allClasses = heapBrowser.scanHeapForClasses()
        
        // When: Filtering with empty search
        let filtered = heapBrowser.filterClasses(allClasses, searchText: "")
        
        // Then: Should return all classes
        XCTAssertEqual(filtered.count, allClasses.count, "Empty search should return all classes")
    }
    
    // MARK: - Sorting Tests
    
    func testSortClassesByInstanceCount() {
        // Given: A heap browser with classes
        var classes = heapBrowser.scanHeapForClasses()
        
        // When: Sorting by instance count (descending)
        heapBrowser.sortClasses(&classes, by: .instanceCount, ascending: false)
        
        // Then: Should be sorted in descending order of instance count
        for i in 0..<(classes.count - 1) {
            XCTAssertGreaterThanOrEqual(classes[i].instanceCount, classes[i + 1].instanceCount,
                                       "Classes should be sorted by instance count (descending)")
        }
    }
    
    func testSortClassesByClassName() {
        // Given: A heap browser with classes
        var classes = heapBrowser.scanHeapForClasses()
        
        // When: Sorting by class name (ascending)
        heapBrowser.sortClasses(&classes, by: .className, ascending: true)
        
        // Then: Should be sorted alphabetically
        for i in 0..<(classes.count - 1) {
            XCTAssertLessThanOrEqual(classes[i].className, classes[i + 1].className,
                                    "Classes should be sorted alphabetically")
        }
    }
    
    // MARK: - Instance Retrieval Tests
    
    func testGetInstancesForClass() {
        // Given: A heap browser and a known class
        let classes = heapBrowser.scanHeapForClasses()
        guard let firstClass = classes.first else {
            XCTFail("Should have at least one class")
            return
        }
        
        // When: Getting instances for that class
        let instances = heapBrowser.getInstances(for: firstClass.className)
        
        // Then: Should return instances
        XCTAssertGreaterThan(instances.count, 0, "Should find instances of the class")
        XCTAssertLessThanOrEqual(instances.count, firstClass.instanceCount,
                                "Instance count should not exceed reported count")
    }
    
    func testInstanceInfoHasRequiredProperties() {
        // Given: A heap browser and instances of a class
        let classes = heapBrowser.scanHeapForClasses()
        guard let firstClass = classes.first else {
            XCTFail("Should have at least one class")
            return
        }
        
        // When: Getting instances
        let instances = heapBrowser.getInstances(for: firstClass.className)
        
        // Then: Each instance should have required properties
        for instance in instances.prefix(3) { // Test first 3 to avoid long test times
            XCTAssertNotEqual(instance.memoryAddress, 0, "Memory address should not be zero")
            XCTAssertFalse(instance.description.isEmpty, "Description should not be empty")
        }
    }
    
    // MARK: - Performance Tests
    
    func testHeapScanPerformance() {
        // Performance test for heap scanning
        self.measure {
            _ = heapBrowser.scanHeapForClasses()
        }
    }
    
    func testInstanceCapLimitsResults() {
        // Given: A heap browser with instance cap
        heapBrowser.maxInstancesPerClass = 10
        
        // When: Getting instances for a class with many instances
        let classes = heapBrowser.scanHeapForClasses()
        guard let classWithManyInstances = classes.first(where: { $0.instanceCount > 10 }) else {
            // Skip test if no class has more than 10 instances
            return
        }
        
        let instances = heapBrowser.getInstances(for: classWithManyInstances.className)
        
        // Then: Should be limited to the cap
        XCTAssertLessThanOrEqual(instances.count, 10, "Instance count should be limited by cap")
    }
}

// MARK: - Mock Classes for Testing

private class TestObject: NSObject {
    let name: String
    
    init(name: String) {
        self.name = name
        super.init()
    }
}

private class AnotherTestObject: NSObject {
    let value: Int
    
    init(value: Int) {
        self.value = value
        super.init()
    }
}