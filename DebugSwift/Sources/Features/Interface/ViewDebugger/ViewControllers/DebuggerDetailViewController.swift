//
//  DebuggerDetailViewController.swift
//  DebugSwift
//
//  Created by Matheus Gois on 05/01/24.
//

import UIKit

final class DebuggerDetailViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()
    
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let imageContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let detailsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let detailsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - Properties
    
    private let snapshot: Snapshot
    
    // MARK: - Initialization
    
    init(snapshot: Snapshot) {
        self.snapshot = snapshot
        super.init(nibName: nil, bundle: nil)
        title = snapshot.element.title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        populateData()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "doc.on.doc"),
            style: .plain,
            target: self,
            action: #selector(copyDetails)
        )
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        
        // Image section
        imageContainerView.addSubview(imageView)
        contentStackView.addArrangedSubview(imageContainerView)
        
        // Details section
        detailsContainerView.addSubview(detailsStackView)
        contentStackView.addArrangedSubview(detailsContainerView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
            
            imageView.leadingAnchor.constraint(equalTo: imageContainerView.leadingAnchor, constant: 16),
            imageView.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor, constant: -16),
            imageView.topAnchor.constraint(equalTo: imageContainerView.topAnchor, constant: 16),
            imageView.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor, constant: -16),
            imageView.heightAnchor.constraint(equalToConstant: 200),
            
            detailsStackView.leadingAnchor.constraint(equalTo: detailsContainerView.leadingAnchor),
            detailsStackView.trailingAnchor.constraint(equalTo: detailsContainerView.trailingAnchor),
            detailsStackView.topAnchor.constraint(equalTo: detailsContainerView.topAnchor),
            detailsStackView.bottomAnchor.constraint(equalTo: detailsContainerView.bottomAnchor)
        ])
    }
    
    private func populateData() {
        // Set image
        if let cgImage = snapshot.snapshotImage {
            imageView.image = UIImage(cgImage: cgImage).outline()
        } else {
            imageContainerView.isHidden = true
        }
        
        // Parse and organize the description
        let description = snapshot.element.description
        let sections = parseDescription(description)
        
        for section in sections {
            let sectionView = createSectionView(title: section.title, content: section.content)
            detailsStackView.addArrangedSubview(sectionView)
        }
    }
    
    private func parseDescription(_ description: String) -> [(title: String, content: String)] {
        var sections: [(String, String)] = []
        let lines = description.components(separatedBy: "\n")
        
        var currentSection = ""
        var currentContent: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Check if it's a section header (starts with "- " and ends with ":")
            if trimmedLine.hasPrefix("- ") && trimmedLine.hasSuffix(":") {
                // Save previous section
                if !currentSection.isEmpty && !currentContent.isEmpty {
                    sections.append((currentSection, currentContent.joined(separator: "\n")))
                }
                
                // Start new section
                currentSection = trimmedLine
                    .replacingOccurrences(of: "- ", with: "")
                    .replacingOccurrences(of: ":", with: "")
                    .trimmingCharacters(in: .whitespaces)
                currentContent = []
            } else if !trimmedLine.isEmpty {
                currentContent.append(line)
            }
        }
        
        // Add last section
        if !currentSection.isEmpty && !currentContent.isEmpty {
            sections.append((currentSection, currentContent.joined(separator: "\n")))
        }
        
        // If no sections were found, create one general section
        if sections.isEmpty && !lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sections.append(("Properties", description))
        }
        
        return sections
    }
    
    private func createSectionView(title: String, content: String) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 0.5
        containerView.layer.borderColor = UIColor.separator.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        
        let contentLabel = UILabel()
        contentLabel.text = content
        contentLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        contentLabel.textColor = .secondaryLabel
        contentLabel.numberOfLines = 0
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(contentLabel)
        
        containerView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
        
        return containerView
    }
    
    // MARK: - Actions
    
    @objc private func copyDetails() {
        UIPasteboard.general.string = snapshot.element.description
        
        let alert = UIAlertController(
            title: "Copied!",
            message: "Details copied to clipboard",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
