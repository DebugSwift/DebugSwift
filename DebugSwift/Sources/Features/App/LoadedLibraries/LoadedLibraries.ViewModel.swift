//
//  LoadedLibraries.ViewModel.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import Foundation
import MachO
import ObjectiveC

final class LoadedLibrariesViewModel: @unchecked Sendable {
    
    // MARK: - Types
    
    enum LibraryFilter {
        case all
        case `public`
        case `private`
    }
    
    struct LoadedLibrary {
        let name: String
        let path: String
        let isPrivate: Bool
        let size: String
        let address: String
        var classes: [String]
        var isExpanded: Bool = false
        var isLoading: Bool = false
    }
    
    // MARK: - Properties
    
    private var allLibraries: [LoadedLibrary] = []
    private(set) var filteredLibraries: [LoadedLibrary] = []
    private var currentFilter: LibraryFilter = .all
    private var searchText: String = ""
    
    // Callback for UI updates
    var onLoadingStateChanged: ((Int) -> Void)?
    
    // MARK: - Public Methods
    
    func loadLibraries() {
        allLibraries = fetchLoadedLibraries()
        applyFilters()
    }
    
    func filterLibraries(by filter: LibraryFilter) {
        currentFilter = filter
        applyFilters()
    }
    
    func searchLibraries(with text: String) {
        searchText = text
        applyFilters()
    }
    
    func toggleLibraryExpansion(at index: Int) {
        guard index < filteredLibraries.count else { return }
        filteredLibraries[index].isExpanded.toggle()
        
        // Load classes if expanding and not yet loaded
        if filteredLibraries[index].isExpanded && filteredLibraries[index].classes.isEmpty {
            // Set loading state
            filteredLibraries[index].isLoading = true
            
            // Load classes asynchronously
            let libraryPath = filteredLibraries[index].path
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let classes = self?.fetchClasses(from: libraryPath) ?? []
                
                DispatchQueue.main.async {
                    guard let self = self, index < self.filteredLibraries.count else { return }
                    self.filteredLibraries[index].classes = classes
                    self.filteredLibraries[index].isLoading = false
                    
                    // Notify UI to update
                    self.onLoadingStateChanged?(index)
                }
            }
        }
    }
    
    func generateReport() -> String {
        var report = "=== Loaded Libraries Report ===\n"
        report += "Generated at: \(Date())\n"
        report += "Total Libraries: \(allLibraries.count)\n"
        report += "Private Libraries: \(allLibraries.filter { $0.isPrivate }.count)\n"
        report += "Public Libraries: \(allLibraries.filter { !$0.isPrivate }.count)\n\n"
        
        for library in allLibraries {
            report += "Library: \(library.name)\n"
            report += "  Path: \(library.path)\n"
            report += "  Type: \(library.isPrivate ? "Private" : "Public")\n"
            report += "  Size: \(library.size)\n"
            report += "  Address: \(library.address)\n"
            
            if !library.classes.isEmpty {
                report += "  Classes (\(library.classes.count)):\n"
                for className in library.classes.prefix(10) {
                    report += "    - \(className)\n"
                }
                if library.classes.count > 10 {
                    report += "    ... and \(library.classes.count - 10) more\n"
                }
            }
            report += "\n"
        }
        
        return report
    }
    
    // MARK: - Private Methods
    
    private func applyFilters() {
        filteredLibraries = allLibraries
        
        // Apply library type filter
        switch currentFilter {
        case .all:
            break
        case .public:
            filteredLibraries = filteredLibraries.filter { !$0.isPrivate }
        case .private:
            filteredLibraries = filteredLibraries.filter { $0.isPrivate }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            let lowercasedSearch = searchText.lowercased()
            filteredLibraries = filteredLibraries.filter { library in
                library.name.lowercased().contains(lowercasedSearch) ||
                library.classes.contains { $0.lowercased().contains(lowercasedSearch) }
            }
        }
    }
    
    private func fetchLoadedLibraries() -> [LoadedLibrary] {
        var libraries: [LoadedLibrary] = []
        
        let imageCount = _dyld_image_count()
        
        for i in 0..<imageCount {
            guard let imageName = _dyld_get_image_name(i) else { continue }
            let name = String(cString: imageName)
            let header = _dyld_get_image_header(i)
            _ = _dyld_get_image_vmaddr_slide(i)
            
            // Get file size
            let fileSize = getFileSize(at: name)
            
            // Determine if library is private
            let isPrivate = isPrivateLibrary(path: name)
            
            // Format address
            let address = String(format: "0x%lX", Int(bitPattern: header))
            
            // Extract library name from path
            let libraryName = (name as NSString).lastPathComponent
            
            libraries.append(LoadedLibrary(
                name: libraryName,
                path: name,
                isPrivate: isPrivate,
                size: fileSize,
                address: address,
                classes: []
            ))
        }
        
        return libraries.sorted { $0.name < $1.name }
    }
    
    private func fetchClasses(from libraryPath: String) -> [String] {
        var classes: [String] = []
        
        guard let handle = dlopen(libraryPath, RTLD_LAZY) else { return classes }
        defer { dlclose(handle) }
        
        // Get all classes registered with the Objective-C runtime
        var classCount: UInt32 = 0
        guard let classList = objc_copyClassList(&classCount) else { return classes }
        // AutoreleasingUnsafeMutablePointer is automatically managed by ARC
        
        // Convert to buffer pointer for safe iteration
        let buffer = UnsafeBufferPointer(start: classList, count: Int(classCount))
        
        for cls in buffer {
            // Check if class belongs to this library
            if let imageName = class_getImageName(cls),
               String(cString: imageName) == libraryPath {
                let className = String(cString: class_getName(cls))
                classes.append(className)
            }
        }
        
        return classes.sorted()
    }
    
    private func isPrivateLibrary(path: String) -> Bool {
        let publicPrefixes = [
            "/System/Library/",
            "/usr/lib/",
            "/Applications/Xcode.app/",
            "/Library/Developer/"
        ]
        
        let privatePrefixes = [
            "/System/Library/PrivateFrameworks/",
            "/usr/lib/system/introspection/"
        ]
        
        // Check private prefixes first
        for prefix in privatePrefixes {
            if path.hasPrefix(prefix) {
                return true
            }
        }
        
        // Check public prefixes
        for prefix in publicPrefixes {
            if path.hasPrefix(prefix) {
                return false
            }
        }
        
        // Default to private for app-specific libraries
        return true
    }
    
    private func getFileSize(at path: String) -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            if let size = attributes[.size] as? Int64 {
                return ByteCountFormatter.string(fromByteCount: size, countStyle: .binary)
            }
        } catch {
            // Ignore errors
        }
        return "Unknown"
    }
} 