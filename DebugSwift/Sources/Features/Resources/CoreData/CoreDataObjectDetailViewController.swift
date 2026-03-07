//
//  CoreDataObjectDetailViewController.swift
//  DebugSwift
//
//  Detail view for a single Core Data managed object
//

import UIKit
import CoreData

@MainActor
final class CoreDataObjectDetailViewController: BaseController {
    
    // MARK: - Properties
    
    private let object: NSManagedObject
    private let entity: CoreDataEntity
    private let context: NSManagedObjectContext
    
    private var isEditMode = false
    private var editedValues: [String: Any] = [:]
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.register(AttributeCell.self, forCellReuseIdentifier: "AttributeCell")
        table.register(RelationshipCell.self, forCellReuseIdentifier: "RelationshipCell")
        return table
    }()
    
    private enum Section: Int, CaseIterable {
        case objectInfo
        case attributes
        case relationships
        
        var title: String {
            switch self {
            case .objectInfo: return "Object Information"
            case .attributes: return "Attributes"
            case .relationships: return "Relationships"
            }
        }
    }
    
    // MARK: - Initialization
    
    init(object: NSManagedObject, entity: CoreDataEntity, context: NSManagedObjectContext) {
        self.object = object
        self.entity = entity
        self.context = context
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
}

// MARK: - Setup

private extension CoreDataObjectDetailViewController {
    func setup() {
        setupViews()
        setupNavigation()
    }
    
    func setupViews() {
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func setupNavigation() {
        title = "Object Detail"
        
        if !DebugSwift.Resources.shared.coreDataReadOnly {
            let editButton = UIBarButtonItem(
                title: isEditMode ? "Done" : "Edit",
                style: isEditMode ? .done : .plain,
                target: self,
                action: #selector(toggleEditMode)
            )
            navigationItem.rightBarButtonItem = editButton
        }
    }
    
    @objc func toggleEditMode() {
        if isEditMode {
            saveChanges()
        } else {
            isEditMode = true
            editedValues = [:]
            setupNavigation()
            tableView.reloadData()
        }
    }
    
    func saveChanges() {
        guard !editedValues.isEmpty else {
            cancelEdit()
            return
        }
        
        let alert = UIAlertController(
            title: "Save Changes",
            message: "Do you want to save the changes to this object?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            self?.performSave()
        })
        
        alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { [weak self] _ in
            self?.cancelEdit()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    func performSave() {
        for (key, value) in editedValues {
            object.setValue(value, forKey: key)
        }
        
        do {
            try CoreDataManager.shared.save(context: context)
            cancelEdit()
        } catch {
            showError(error)
        }
    }
    
    func cancelEdit() {
        isEditMode = false
        editedValues = [:]
        setupNavigation()
        tableView.reloadData()
    }
    
    func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension CoreDataObjectDetailViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { return 0 }
        
        switch sectionType {
        case .objectInfo:
            return 2
        case .attributes:
            return entity.attributes.count
        case .relationships:
            return entity.relationships.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        
        switch sectionType {
        case .objectInfo:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            if indexPath.row == 0 {
                cell.textLabel?.text = "Entity"
                cell.detailTextLabel?.text = entity.name
            } else {
                cell.textLabel?.text = "Object ID"
                cell.detailTextLabel?.text = object.objectID.uriRepresentation().lastPathComponent
                cell.detailTextLabel?.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
            }
            cell.selectionStyle = .none
            return cell
            
        case .attributes:
            let cell = tableView.dequeueReusableCell(withIdentifier: "AttributeCell", for: indexPath) as! AttributeCell
            let attribute = entity.attributes[indexPath.row]
            let value = editedValues[attribute.name] ?? object.value(forKey: attribute.name)
            cell.configure(
                attribute: attribute,
                value: value,
                isEditMode: isEditMode,
                onValueChange: { [weak self] newValue in
                    self?.editedValues[attribute.name] = newValue
                }
            )
            return cell
            
        case .relationships:
            let cell = tableView.dequeueReusableCell(withIdentifier: "RelationshipCell", for: indexPath) as! RelationshipCell
            let relationship = entity.relationships[indexPath.row]
            let value = object.value(forKey: relationship.name)
            cell.configure(relationship: relationship, value: value)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionType = Section(rawValue: section) else { return nil }
        return sectionType.title
    }
}

// MARK: - UITableViewDelegate

extension CoreDataObjectDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let sectionType = Section(rawValue: indexPath.section) else { return }
        
        if sectionType == .relationships {
            let relationship = entity.relationships[indexPath.row]
            navigateToRelationship(relationship)
        } else if sectionType == .attributes {
            let attribute = entity.attributes[indexPath.row]
            if isEditMode {
                showEditDialog(for: attribute)
            }
        }
    }
    
    func navigateToRelationship(_ relationship: CoreDataRelationship) {
        guard let value = object.value(forKey: relationship.name) else { return }
        
        if relationship.isToMany {
            if let relatedObjects = value as? Set<NSManagedObject>, !relatedObjects.isEmpty {
                let relatedVC = CoreDataRelatedObjectsViewController(
                    relationship: relationship,
                    objects: Array(relatedObjects),
                    context: context
                )
                navigationController?.pushViewController(relatedVC, animated: true)
            }
        } else {
            if let relatedObject = value as? NSManagedObject {
                let relatedEntityName = relatedObject.entity.name ?? relationship.destinationEntity
                let relatedEntity = CoreDataManager.shared.getEntities(for: context)
                    .first { $0.name == relatedEntityName }
                
                if let relatedEntity = relatedEntity {
                    let detailVC = CoreDataObjectDetailViewController(
                        object: relatedObject,
                        entity: relatedEntity,
                        context: context
                    )
                    navigationController?.pushViewController(detailVC, animated: true)
                }
            }
        }
    }
    
    func showEditDialog(for attribute: CoreDataAttribute) {
        let alert = UIAlertController(
            title: "Edit \(attribute.name)",
            message: "Enter new value for \(attribute.type)",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            let currentValue = self.editedValues[attribute.name] ?? self.object.value(forKey: attribute.name)
            textField.text = self.formatValueForEditing(currentValue)
            textField.placeholder = attribute.type
        }
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let self = self,
                  let textField = alert?.textFields?.first,
                  let text = textField.text else { return }
            
            if let convertedValue = self.convertValue(text, to: attribute.type) {
                self.editedValues[attribute.name] = convertedValue
                self.tableView.reloadData()
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    func formatValueForEditing(_ value: Any?) -> String {
        guard let value = value else { return "" }
        
        switch value {
        case let date as Date:
            let formatter = ISO8601DateFormatter()
            return formatter.string(from: date)
        case let data as Data:
            return data.base64EncodedString()
        default:
            return String(describing: value)
        }
    }
    
    func convertValue(_ text: String, to type: String) -> Any? {
        switch type {
        case "Int16": return Int16(text)
        case "Int32": return Int32(text)
        case "Int64": return Int64(text)
        case "Double": return Double(text)
        case "Float": return Float(text)
        case "Bool": return Bool(text)
        case "String": return text
        case "Date":
            let formatter = ISO8601DateFormatter()
            return formatter.date(from: text)
        case "Data":
            return Data(base64Encoded: text)
        default:
            return text
        }
    }
}

// MARK: - Attribute Cell

final class AttributeCell: UITableViewCell {
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .medium)
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .right
        return label
    }()
    
    private let typeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 11)
        label.textColor = .tertiaryLabel
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(nameLabel)
        contentView.addSubview(valueLabel)
        contentView.addSubview(typeLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.4),
            
            typeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            typeLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            typeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            valueLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            valueLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            valueLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(
        attribute: CoreDataAttribute,
        value: Any?,
        isEditMode: Bool,
        onValueChange: @escaping (Any?) -> Void
    ) {
        nameLabel.text = attribute.name
        typeLabel.text = attribute.type + (attribute.isOptional ? "?" : "")
        valueLabel.text = formatValue(value)
        
        if isEditMode {
            accessoryType = .disclosureIndicator
            selectionStyle = .default
        } else {
            accessoryType = .none
            selectionStyle = .none
        }
    }
    
    private func formatValue(_ value: Any?) -> String {
        guard let value = value else { return "nil" }
        
        switch value {
        case let date as Date:
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .medium
            return formatter.string(from: date)
        case let data as Data:
            return "\(data.count) bytes"
        case let number as NSNumber:
            return number.stringValue
        default:
            return String(describing: value)
        }
    }
}

// MARK: - Relationship Cell

final class RelationshipCell: UITableViewCell {
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .medium)
        return label
    }()
    
    private let detailLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    private let destinationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 11)
        label.textColor = .tertiaryLabel
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(nameLabel)
        contentView.addSubview(detailLabel)
        contentView.addSubview(destinationLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            
            destinationLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            destinationLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            destinationLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            detailLabel.topAnchor.constraint(equalTo: destinationLabel.bottomAnchor, constant: 4),
            detailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            detailLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(relationship: CoreDataRelationship, value: Any?) {
        nameLabel.text = relationship.name
        destinationLabel.text = "→ \(relationship.destinationEntity)"
        
        if let value = value {
            if relationship.isToMany {
                if let set = value as? Set<NSManagedObject> {
                    detailLabel.text = "\(set.count) objects"
                    accessoryType = .disclosureIndicator
                } else {
                    detailLabel.text = "Empty"
                    accessoryType = .none
                }
            } else {
                if let _ = value as? NSManagedObject {
                    detailLabel.text = "1 object"
                    accessoryType = .disclosureIndicator
                } else {
                    detailLabel.text = "nil"
                    accessoryType = .none
                }
            }
        } else {
            detailLabel.text = "nil"
            accessoryType = .none
        }
    }
}

// MARK: - Related Objects View Controller

@MainActor
final class CoreDataRelatedObjectsViewController: BaseController {
    private let relationship: CoreDataRelationship
    private let objects: [NSManagedObject]
    private let context: NSManagedObjectContext
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        return table
    }()
    
    init(relationship: CoreDataRelationship, objects: [NSManagedObject], context: NSManagedObjectContext) {
        self.relationship = relationship
        self.objects = objects
        self.context = context
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = relationship.name
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension CoreDataRelatedObjectsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let object = objects[indexPath.row]
        
        if #available(iOS 14.0, *) {
            var content = cell.defaultContentConfiguration()
            content.text = "Object \(indexPath.row + 1)"
            content.secondaryText = object.objectID.uriRepresentation().lastPathComponent
            cell.contentConfiguration = content
        } else {
            cell.textLabel?.text = "Object \(indexPath.row + 1)"
            cell.detailTextLabel?.text = object.objectID.uriRepresentation().lastPathComponent
        }
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let object = objects[indexPath.row]
        let relatedEntity = CoreDataManager.shared.getEntities(for: context)
            .first { $0.name == relationship.destinationEntity }
        
        if let relatedEntity = relatedEntity {
            let detailVC = CoreDataObjectDetailViewController(
                object: object,
                entity: relatedEntity,
                context: context
            )
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}
