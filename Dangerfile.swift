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
        // checkTitle() - Removed per user request
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

    func checkTitle() {
        let result = prTitle.range(
            of: #"\[[A-zÀ-ú0-9 ]*\][A-zÀ-ú0-9- ]+"#,
            options: .regularExpression
        ) != nil

        if !result {
            let message = "❌ The PR title must follow the format: [Feature or Flow] What was done"
            fail(message)
        }
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
        
        // Calculate coverage for DebugSwift target
        var totalLines = 0
        var coveredLines = 0
        var debugSwiftCoverage: Double = 0
        
        for target in targets {
            guard let name = target["name"] as? String,
                  name.contains("DebugSwift"),
                  !name.contains("Tests") else {
                continue
            }
            
            if let lineCoverage = target["lineCoverage"] as? Double {
                debugSwiftCoverage = lineCoverage * 100
            }
            
            if let executableLines = target["executableLines"] as? Int,
               let coveredLinesCount = target["coveredLines"] as? Int {
                totalLines = executableLines
                coveredLines = coveredLinesCount
            }
        }
        
        let minimumCoverage = 70.0
        
        if debugSwiftCoverage > 0 {
            let coverageMessage = String(format: "Code Coverage: %.1f%% (%d/%d lines)", 
                                        debugSwiftCoverage, 
                                        coveredLines, 
                                        totalLines)
            
            if debugSwiftCoverage < minimumCoverage {
                warn("⚠️ \(coverageMessage) - Below minimum threshold of \(Int(minimumCoverage))%")
            } else {
                message("✅ \(coverageMessage)")
            }
        } else {
            warn("⚠️ No coverage data found for DebugSwift target.")
        }
    }
}
