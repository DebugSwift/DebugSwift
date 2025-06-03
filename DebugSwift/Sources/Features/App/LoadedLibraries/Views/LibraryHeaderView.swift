//
//  LibraryHeaderView.swift
//  DebugSwift
//
//  Created by DebugSwift on 2024.
//

import UIKit

final class LibraryHeaderView: UIView {
    
    // MARK: - Properties
    
    var onToggle: (() -> Void)?
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.darkGray.withAlphaComponent(0.3)
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let pathLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 12)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingMiddle
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let typeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let sizeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 11)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let expandIndicator: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            indicator = UIActivityIndicatorView(style: .medium)
        } else {
            indicator = UIActivityIndicatorView(style: .white)
        }
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    // MARK: - Setup
    
    private func setup() {
        addSubview(containerView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(pathLabel)
        containerView.addSubview(typeLabel)
        containerView.addSubview(sizeLabel)
        containerView.addSubview(expandIndicator)
        containerView.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: typeLabel.leadingAnchor, constant: -8),
            
            typeLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            typeLabel.trailingAnchor.constraint(equalTo: expandIndicator.leadingAnchor, constant: -12),
            typeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            typeLabel.heightAnchor.constraint(equalToConstant: 20),
            
            pathLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            pathLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            pathLabel.trailingAnchor.constraint(equalTo: expandIndicator.leadingAnchor, constant: -12),
            
            sizeLabel.topAnchor.constraint(equalTo: pathLabel.bottomAnchor, constant: 4),
            sizeLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            sizeLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            
            expandIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            expandIndicator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            expandIndicator.widthAnchor.constraint(equalToConstant: 20),
            expandIndicator.heightAnchor.constraint(equalToConstant: 20),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: expandIndicator.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: expandIndicator.centerYAnchor)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        containerView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Configuration
    
    func configure(with library: LoadedLibrariesViewModel.LoadedLibrary) {
        // Extract a cleaner name from the path if needed
        let displayName: String
        if library.name.hasSuffix(".app") || library.name.hasSuffix(".framework") || library.name.hasSuffix(".dylib") {
            displayName = library.name
        } else if library.path.contains(".app/") {
            // For app executables, show the app name
            let components = library.path.components(separatedBy: ".app/")
            if components.count > 1 {
                let appPath = components[0] + ".app"
                displayName = (appPath as NSString).lastPathComponent
            } else {
                displayName = library.name
            }
        } else {
            displayName = library.name
        }
        
        nameLabel.text = displayName
        pathLabel.text = library.path
        sizeLabel.text = "Size: \(library.size) • Address: \(library.address)"
        
        // Configure type label
        typeLabel.text = library.isPrivate ? " Private " : " Public "
        typeLabel.backgroundColor = library.isPrivate ? 
            UIColor.systemRed.withAlphaComponent(0.3) : 
            UIColor.systemGreen.withAlphaComponent(0.3)
        typeLabel.textColor = library.isPrivate ? .systemRed : .systemGreen
        
        // Configure expand indicator and loading state
        if library.isLoading {
            expandIndicator.isHidden = true
            loadingIndicator.startAnimating()
        } else {
            expandIndicator.isHidden = false
            loadingIndicator.stopAnimating()
            let imageName = library.isExpanded ? "chevron.down" : "chevron.right"
            expandIndicator.image = UIImage(systemName: imageName)
        }
    }
    
    // MARK: - Actions
    
    @objc private func handleTap() {
        onToggle?()
    }
} 