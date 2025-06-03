//
//  Resources.TabbedController.swift
//  DebugSwift
//
//  Created by DebugSwift on 01/01/25.
//

import UIKit

final class ResourcesTabbedController: BaseController {
    
    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        return stackView
    }()
    
    private lazy var addButton: UIButton = {
        let button = createActionButton(
            icon: UIImage.named("plus.circle.fill", default: "+"),
            color: .systemBlue
        )
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var exportButton: UIButton = {
        let button = createActionButton(
            icon: UIImage.named("square.and.arrow.up.fill", default: "↗"),
            color: .systemGreen
        )
        button.addTarget(self, action: #selector(exportButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var deleteAllButton: UIButton = {
        let button = createActionButton(
            icon: UIImage.named("trash.circle.fill", default: "🗑"),
            color: .systemRed
        )
        button.addTarget(self, action: #selector(deleteAllButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private func createActionButton(icon: UIImage?, color: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Set icon
        if let icon = icon {
            button.setImage(icon.withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
        }
        
        button.backgroundColor = color
        button.layer.cornerRadius = 22
        button.contentEdgeInsets = UIEdgeInsets(top: 11, left: 11, bottom: 11, right: 11)
        
        // Add subtle shadow
        button.layer.shadowColor = color.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.3
        
        // Add touch feedback
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        return button
    }
    
    private lazy var segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["UserDefaults", "Keychain"])
        control.translatesAutoresizingMaskIntoConstraints = false
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        if #available(iOS 13.0, *) {
            control.selectedSegmentTintColor = .systemBlue
            control.backgroundColor = .secondarySystemBackground
        }
        return control
    }()
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        return view
    }()
    
    private lazy var separatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .separator
        return view
    }()
    
    private lazy var userDefaultsController: ResourcesGenericController = {
        let viewModel = ResourcesUserDefaultsViewModel()
        let controller = ResourcesGenericController(viewModel: viewModel)
        controller.hideNavigationAddButton = true
        return controller
    }()
    
    private lazy var keychainController: ResourcesGenericController = {
        let viewModel = ResourcesKeychainViewModel()
        let controller = ResourcesGenericController(viewModel: viewModel)
        controller.hideNavigationAddButton = true
        return controller
    }()
    
    private var currentViewController: UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        showUserDefaults()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateButtonStates()
    }
    
    private func setupUI() {
        title = "Persistent Data"
        view.backgroundColor = .black
        
        // Add buttons to stack
        buttonStackView.addArrangedSubview(addButton)
        buttonStackView.addArrangedSubview(exportButton)
        buttonStackView.addArrangedSubview(deleteAllButton)
        
        view.addSubview(buttonStackView)
        view.addSubview(separatorView)
        view.addSubview(segmentedControl)
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            buttonStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonStackView.heightAnchor.constraint(equalToConstant: 44),
            
            separatorView.topAnchor.constraint(equalTo: buttonStackView.bottomAnchor, constant: 10),
            separatorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5),
            
            segmentedControl.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: 10),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            segmentedControl.heightAnchor.constraint(equalToConstant: 40),
            
            containerView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 10),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func updateButtonStates() {
        guard let genericController = currentViewController as? ResourcesGenericController else { return }
        
        let hasItems = genericController.viewModel.numberOfItems() > 0
        
        // Always enable add button
        addButton.isEnabled = true
        addButton.alpha = 1.0
        
        // Enable/disable other buttons based on content
        exportButton.isEnabled = hasItems
        exportButton.alpha = hasItems ? 1.0 : 0.5
        
        deleteAllButton.isEnabled = hasItems
        deleteAllButton.alpha = hasItems ? 1.0 : 0.5
    }
    
    @objc private func addButtonTapped() {
        if let genericController = currentViewController as? ResourcesGenericController {
            genericController.triggerAddAction()
        }
    }
    
    @objc private func exportButtonTapped() {
        if let genericController = currentViewController as? ResourcesGenericController {
            genericController.triggerExportAction()
        }
    }
    
    @objc private func deleteAllButtonTapped() {
        if let genericController = currentViewController as? ResourcesGenericController {
            genericController.triggerDeleteAllAction()
        }
    }
    
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            sender.alpha = 0.8
        }
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = .identity
            sender.alpha = sender.isEnabled ? 1.0 : 0.5
        }
    }
    
    @objc private func segmentChanged() {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            showUserDefaults()
        case 1:
            showKeychain()
        default:
            break
        }
        updateButtonStates()
    }
    
    private func showUserDefaults() {
        show(userDefaultsController)
    }
    
    private func showKeychain() {
        show(keychainController)
    }
    
    private func show(_ viewController: UIViewController) {
        // Remove current child
        if let current = currentViewController {
            current.willMove(toParent: nil)
            current.view.removeFromSuperview()
            current.removeFromParent()
        }
        
        // Add new child
        addChild(viewController)
        containerView.addSubview(viewController.view)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            viewController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            viewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            viewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            viewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        viewController.didMove(toParent: self)
        currentViewController = viewController
        
        // Set up refresh callback
        if let genericController = viewController as? ResourcesGenericController {
            genericController.onDataChanged = { [weak self] in
                self?.updateButtonStates()
            }
        }
    }
} 