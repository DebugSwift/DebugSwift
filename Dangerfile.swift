// MARK: Imports

import Danger
import DangerXCodeSummary
import Foundation

// MARK: Validate

Validator.shared.validate()

// MARK: Lint

SwiftLint.lint(configFile: ".swiftlint.yml")

// MARK: Validation rules

internal class Validator {
    // MARK: Lifecycle
    // Private initializer and shared instance for Validator.

    private init() {}
    internal static let shared = Validator()
    private var danger = Danger()

    // MARK: Properties
    // Properties related to PR details and changes.

    private lazy var additions = danger.github.pullRequest.additions!
    private lazy var deletions = danger.github.pullRequest.deletions!
    private lazy var changedFiles = danger.github.pullRequest.changedFiles!

    private lazy var modified = danger.git.modifiedFiles
    private lazy var editedFiles = modified + danger.git.createdFiles
    private lazy var prTitle = danger.github.pullRequest.title

    private lazy var branchHeadName = danger.github.pullRequest.head.ref
    private lazy var branchBaseName = danger.github.pullRequest.base.ref

    // Methods
    // Methods for various validation checks.

    internal func validate() {
        checkSize()
        checkDescription()
        checkUnitTest()
        checkAssignee()
        checkModifiedFiles()
        checkFails()

        logResume()
    }
}

internal class DescriptionValidator {
    // MARK: Lifecycle
    // Private initializer and shared instance for DescriptionValidator.

    private init() {}
    internal static let shared = DescriptionValidator()
    private var danger = Danger()

    // MARK: Properties
    // Property to store the PR body.

    private lazy var body = danger.github.pullRequest.body ?? ""

    // Methods
    // Method to validate PR description.

    internal func validate() {
        let message = "PR does not have a description. You must provide a description of the changes made."

        guard !body.isEmpty else {
            fail(message)
            return
        }
    }
}

internal class UnitTestValidator {
    // MARK: Lifecycle
    // Private initializer and shared instance for UnitTestValidator.

    private init() {}
    internal static let shared = UnitTestValidator()
    private var danger = Danger()

    // Methods
    // Methods for unit test validation.

    internal func validate() {
        checkUnitTestSummary()
        checkUnitTestCoverage()
    }
}

// MARK: Validator Methods
// Extension with methods for Validator class.

fileprivate extension Validator {
    func checkSize() {
        if (additions + deletions) > ValidationRules.bigPRThreshold {
            let message =
            """
            The size of the PR seems relatively large. \
            If possible, in the future if the PR contains multiple changes, split each into a separate PR. \
            This helps in faster and easier review.
            """
            warn(message)
        }
    }

    func checkDescription() {
        DescriptionValidator.shared.validate()
    }

    func checkUnitTest() {
        UnitTestValidator.shared.validate()
    }

    func checkAssignee() {
        if danger.github.pullRequest.assignee == nil {
            warn("Please assign yourself to the PR.")
        }
    }

    func checkModifiedFiles() {
        if changedFiles > ValidationRules.maxChangedFiles {
            let message =
            """
            PR contains too many changed files. If possible, next time try to split into smaller features.
            """
            warn(message)
        }
    }

    func checkFails() {
        if !danger.fails.isEmpty {
            _ = danger.utils.exec("touch Danger-has-fails.swift")
        }
    }

    func logResume() {
        let overview =
        """
        The PR added \(additions) and removed \(deletions) lines. \(changedFiles) file(s) changed.
        """
        message(overview)
    }
}

// MARK: Constants
// Constants related to validation rules.

private enum ValidationRules {
    static let maxChangedFiles = 20
    static let bigPRThreshold = 3000
}

// MARK: Extensions
// Extension with additional file-related methods.

fileprivate extension Danger.File {
    var isInSources: Bool { hasPrefix("Sources/") }
    var isInTests: Bool { hasPrefix("Tests/") }

    var isSourceFile: Bool {
        hasSuffix(".swift") || hasSuffix(".h") || hasSuffix(".m")
    }

    var isSwiftPackageDefintion: Bool {
        hasPrefix("Package") && hasSuffix(".swift")
    }

    var isDangerfile: Bool {
        self == "Dangerfile.swift"
    }
}

// MARK: UnitTestValidator Methods
// Extension with methods for UnitTestValidator class.

fileprivate extension UnitTestValidator {
    func checkUnitTestSummary() {
        let file = "build/reports/errors.json"
        if FileManager.default.fileExists(atPath: file) {
            let summary = XCodeSummary(filePath: file) { result in
                result.category != .warning
            }
            summary.report()
        }
    }

    func checkUnitTestCoverage() {
        let xcresultPath = "Example/fastlane/test_output/Example.xcresult"
        
        guard FileManager.default.fileExists(atPath: xcresultPath) else {
            warn("⚠️ No test results found. Skipping coverage check.")
            return
        }
        
        // Use xcrun xccov to extract coverage data (compatible with Xcode 16.4+)
        let coverageCommand = "xcrun xccov view --report --json '\(xcresultPath)'"
        let coverageResult = danger.utils.exec(coverageCommand)
        
        guard !coverageResult.isEmpty else {
            warn("⚠️ Failed to extract coverage data from xcresult bundle.")
            return
        }
        
        // Parse coverage JSON
        guard let jsonData = coverageResult.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let targets = json["targets"] as? [[String: Any]] else {
            warn("⚠️ Failed to parse coverage data.")
            return
        }
        
        // Debug: List all available targets
        let targetNames = targets.compactMap { $0["name"] as? String }
        print("🔍 DEBUG: Available targets: \(targetNames.joined(separator: ", "))")
        
        // Calculate overall coverage for DebugSwift-related targets (try multiple patterns)
        var totalLines = 0
        var coveredLines = 0
        var debugSwiftCoverage: Double = 0
        var foundTarget = false
        
        for target in targets {
            guard let name = target["name"] as? String else { continue }
            
            // Match "DebugSwift" or frameworks that contain it
            let isDebugSwiftTarget = name.contains("DebugSwift") || 
                                     name == "Example.app" // Example app includes DebugSwift framework
            let isTestTarget = name.contains("Tests") || name.contains("Test")
            
            guard isDebugSwiftTarget && !isTestTarget else {
                continue
            }
            
            foundTarget = true
            
            if let lineCoverage = target["lineCoverage"] as? Double {
                debugSwiftCoverage = lineCoverage * 100
            }
            
            if let executableLines = target["executableLines"] as? Int,
               let coveredLinesCount = target["coveredLines"] as? Int {
                totalLines += executableLines
                coveredLines += coveredLinesCount
            }
        }
        
        let minimumCoverage = 70.0
        
        // Report overall coverage
        if foundTarget && debugSwiftCoverage > 0 {
            let coverageMessage = String(format: "📊 **Overall Code Coverage**: %.1f%% (%d/%d lines)", 
                                        debugSwiftCoverage, 
                                        coveredLines, 
                                        totalLines)
            
            if debugSwiftCoverage < minimumCoverage {
                warn("⚠️ \(coverageMessage) - Below minimum threshold of \(Int(minimumCoverage))%")
            } else {
                message("✅ \(coverageMessage)")
            }
        } else {
            warn("⚠️ No coverage data found. Available targets: \(targetNames.joined(separator: ", "))")
            return
        }
        
        // Report per-file coverage for modified Swift files
        checkModifiedFilesCoverage(xcresultPath: xcresultPath, targets: targets)
    }
    
    func checkModifiedFilesCoverage(xcresultPath: String, targets: [[String: Any]]) {
        // Get modified Swift files from PR
        let modifiedSwiftFiles = danger.git.modifiedFiles.filter { $0.hasSuffix(".swift") && $0.isInSources }
        let createdSwiftFiles = danger.git.createdFiles.filter { $0.hasSuffix(".swift") && $0.isInSources }
        let allChangedFiles = modifiedSwiftFiles + createdSwiftFiles
        
        guard !allChangedFiles.isEmpty else {
            return
        }
        
        // Extract file-level coverage from all targets
        var fileCoverageData: [(file: String, coverage: Double, covered: Int, total: Int)] = []
        
        for target in targets {
            guard let name = target["name"] as? String else { continue }
            
            // Skip test targets
            guard !name.contains("Tests") && !name.contains("Test") else {
                continue
            }
            
            guard let files = target["files"] as? [[String: Any]] else {
                continue
            }
            
            for fileData in files {
                guard let path = fileData["path"] as? String else { continue }
                
                // Check if this file was changed in the PR
                let fileName = (path as NSString).lastPathComponent
                let matchingChangedFile = allChangedFiles.first { changedFile in
                    changedFile.contains(fileName) || path.contains(changedFile)
                }
                
                guard matchingChangedFile != nil else { continue }
                
                let lineCoverage = (fileData["lineCoverage"] as? Double) ?? 0.0
                let coveredLines = (fileData["coveredLines"] as? Int) ?? 0
                let executableLines = (fileData["executableLines"] as? Int) ?? 0
                
                // Only add if not already in the list (avoid duplicates from multiple targets)
                if !fileCoverageData.contains(where: { $0.file == fileName }) {
                    fileCoverageData.append((
                        file: fileName,
                        coverage: lineCoverage * 100,
                        covered: coveredLines,
                        total: executableLines
                    ))
                }
            }
        }
        
        // Report per-file coverage
        if !fileCoverageData.isEmpty {
            var coverageReport = "\n### 📝 Coverage for Changed Files\n\n"
            coverageReport += "| File | Coverage | Lines |\n"
            coverageReport += "|------|----------|-------|\n"
            
            for fileData in fileCoverageData.sorted(by: { $0.coverage < $1.coverage }) {
                let emoji = fileData.coverage >= 70 ? "✅" : "⚠️"
                coverageReport += String(format: "| %@ `%@` | %.1f%% | %d/%d |\n",
                                       emoji,
                                       fileData.file,
                                       fileData.coverage,
                                       fileData.covered,
                                       fileData.total)
            }
            
            message(coverageReport)
        }
    }
}
