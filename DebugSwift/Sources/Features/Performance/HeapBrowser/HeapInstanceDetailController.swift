//
//  HeapInstanceDetailController.swift
//  DebugSwift
//
//  Created by Claude Code on 16/08/25.
//

import UIKit

final class HeapInstanceDetailController: BaseController {
    
    // MARK: - Properties
    
    private let instance: HeapObjectBrowser.InstanceInfo
    
    // MARK: - UI Components
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // MARK: - Initialization
    
    init(instance: HeapObjectBrowser.InstanceInfo) {
        self.instance = instance
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureContent()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Instance Detail"
        view.backgroundColor = .systemBackground
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Stack view
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func configureContent() {
        // Memory Address Section
        let addressSection = createInfoSection(
            title: "Memory Address",
            content: String(format: "0x%016lx", instance.memoryAddress)
        )
        stackView.addArrangedSubview(addressSection)
        
        // Description Section
        let descriptionSection = createInfoSection(
            title: "Description",
            content: instance.description
        )
        stackView.addArrangedSubview(descriptionSection)
        
        // Retain Count Section (if available)
        if let retainCount = instance.retainCount {
            let retainCountSection = createInfoSection(
                title: "Retain Count",
                content: "\(retainCount)"
            )
            stackView.addArrangedSubview(retainCountSection)
        }
        
        // Properties Section
        if !instance.properties.isEmpty {
            let propertiesSection = createPropertiesSection()
            stackView.addArrangedSubview(propertiesSection)
        }
        
        // Allocation Backtrace Section (placeholder for future implementation)
        let backtraceSection = createInfoSection(
            title: "Allocation Backtrace",
            content: "Feature coming soon - stack trace of where this object was allocated"
        )
        stackView.addArrangedSubview(backtraceSection)
    }
    
    // MARK: - Helper Methods
    
    private func createInfoSection(title: String, content: String) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 8
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        
        let contentLabel = UILabel()
        contentLabel.text = content
        contentLabel.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        contentLabel.textColor = .secondaryLabel
        contentLabel.numberOfLines = 0
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, contentLabel])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
        
        return containerView
    }
    
    private func createPropertiesSection() -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 8
        
        let titleLabel = UILabel()
        titleLabel.text = "Properties (\(instance.properties.count))"
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        
        let propertiesStackView = UIStackView()
        propertiesStackView.axis = .vertical
        propertiesStackView.spacing = 8
        
        // Add each property
        for property in instance.properties {
            let propertyView = createPropertyView(property: property)
            propertiesStackView.addArrangedSubview(propertyView)
        }
        
        let mainStackView = UIStackView(arrangedSubviews: [titleLabel, propertiesStackView])
        mainStackView.axis = .vertical
        mainStackView.spacing = 12
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            mainStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            mainStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            mainStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
        
        return containerView
    }
    
    private func createPropertyView(property: HeapObjectBrowser.PropertyInfo) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 6
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.separator.cgColor
        
        let nameLabel = UILabel()
        nameLabel.text = property.name
        nameLabel.font = .systemFont(ofSize: 14, weight: .medium)
        nameLabel.textColor = .label
        
        let typeLabel = UILabel()
        typeLabel.text = property.type
        typeLabel.font = .systemFont(ofSize: 12, weight: .regular)
        typeLabel.textColor = .systemBlue
        
        let valueLabel = UILabel()
        valueLabel.text = property.value
        valueLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        valueLabel.textColor = .secondaryLabel
        valueLabel.numberOfLines = 2
        valueLabel.lineBreakMode = .byTruncatingTail
        
        let nameTypeStack = UIStackView(arrangedSubviews: [nameLabel, typeLabel])
        nameTypeStack.axis = .horizontal
        nameTypeStack.spacing = 8
        nameTypeStack.distribution = .fill
        nameTypeStack.alignment = .firstBaseline
        
        let mainStack = UIStackView(arrangedSubviews: [nameTypeStack, valueLabel])
        mainStack.axis = .vertical
        mainStack.spacing = 4
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            mainStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            mainStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            mainStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])
        
        // Set content hugging and compression resistance
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        typeLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        return containerView
    }
}
