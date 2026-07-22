//
//  ColorPaletteController.swift
//  DebugSwift
//

import UIKit

final class ColorPaletteController: BaseController {

    private enum Section: Int, CaseIterable {
        case summary
        case issues
        case groups
    }

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .black
        tableView.separatorColor = .darkGray
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        return tableView
    }()

    private var palette: ColorPaletteSnapshot?
    private var visibleGroups: [ColorGroup] { palette?.groups ?? [] }
    private var visibleIssues: [PaletteIssue] { palette?.statistics.issues ?? [] }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Color Palette"
        view.backgroundColor = .black

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                image: UIImage(systemName: "square.and.arrow.up"),
                style: .plain,
                target: self,
                action: #selector(exportTapped)
            ),
            UIBarButtonItem(
                image: UIImage(systemName: "arrow.clockwise"),
                style: .plain,
                target: self,
                action: #selector(refreshTapped)
            )
        ]

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ColorSwatchCell.self, forCellReuseIdentifier: ColorSwatchCell.identifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "summary")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "issue")
        tableView.register(PaletteHeaderView.self, forHeaderFooterViewReuseIdentifier: PaletteHeaderView.identifier)
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension

        extractAndReload()
    }

    private func extractAndReload() {
        palette = ColorPaletteExtractor.shared.extract()
        tableView.reloadData()
    }

    @objc private func refreshTapped() {
        extractAndReload()
    }

    @objc private func exportTapped() {
        guard let palette else { return }
        let alert = UIAlertController(
            title: "Export Palette",
            message: "Choose a format",
            preferredStyle: .actionSheet
        )
        for format in ColorPaletteExportFormat.allCases {
            alert.addAction(UIAlertAction(title: format.displayName, style: .default) { [weak self] _ in
                self?.share(palette: palette, format: format)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = alert.popoverPresentationController {
            pop.barButtonItem = navigationItem.rightBarButtonItems?.first
        }
        present(alert, animated: true)
    }

    private func share(palette: ColorPaletteSnapshot, format: ColorPaletteExportFormat) {
        let content = palette.export(as: format)
        let filename = "palette.\(format.fileExtension)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? content.data(using: .utf8)?.write(to: url)

        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let pop = activity.popoverPresentationController {
            pop.barButtonItem = navigationItem.rightBarButtonItems?.first
        }
        present(activity, animated: true)
    }
}

extension ColorPaletteController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        guard palette != nil else { return 0 }
        return Section.allCases.count + max(0, visibleGroups.count - 1)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let palette else { return 0 }
        if section == 0 { return 1 }
        if section == 1 { return visibleIssues.isEmpty ? 0 : visibleIssues.count }
        let groupIndex = section - 2
        guard groupIndex >= 0, groupIndex < palette.groups.count else { return 0 }
        return palette.groups[groupIndex].colors.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let palette else { return UITableViewCell() }

        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "summary", for: indexPath)
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.textColor = .white
            cell.textLabel?.font = .systemFont(ofSize: 14)
            cell.textLabel?.text = summaryText(for: palette)
            return cell
        }

        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "issue", for: indexPath)
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.textColor = .systemYellow
            cell.textLabel?.font = .systemFont(ofSize: 13)
            cell.textLabel?.text = visibleIssues[indexPath.row].message
            return cell
        }

        let groupIndex = indexPath.section - 2
        let group = palette.groups[groupIndex]
        let color = group.colors[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ColorSwatchCell.identifier, for: indexPath) as! ColorSwatchCell
        cell.configure(with: color)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let palette else { return nil }
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: PaletteHeaderView.identifier) as? PaletteHeaderView
        if section == 0 {
            header?.configure(title: "Summary", count: palette.statistics.totalColors)
        } else if section == 1 {
            guard !visibleIssues.isEmpty else { return nil }
            header?.configure(title: "Issues Detected", count: visibleIssues.count)
        } else {
            let groupIndex = section - 2
            guard groupIndex < palette.groups.count else { return nil }
            let group = palette.groups[groupIndex]
            header?.configure(title: "\(group.category.displayName) — \(group.name)", count: group.colors.count)
        }
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1, visibleIssues.isEmpty { return .leastNonzeroMagnitude }
        return 36
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section >= 2, let palette else { return }
        let groupIndex = indexPath.section - 2
        let color = palette.groups[groupIndex].colors[indexPath.row]
        let detail = ColorDetailController(color: color, palette: palette)
        navigationController?.pushViewController(detail, animated: true)
    }

    private func summaryText(for palette: ColorPaletteSnapshot) -> String {
        var lines: [String] = []
        if let screen = palette.screenName {
            lines.append("Screen: \(screen)")
        }
        lines.append("Colors: \(palette.statistics.totalColors)  •  Groups: \(palette.statistics.totalGroups)  •  Usages: \(palette.statistics.totalUsages)")
        if let most = palette.statistics.mostUsed {
            lines.append("Most used: \(most.hex) (\(most.usageCount)×)")
        }
        return lines.joined(separator: "\n")
    }
}
