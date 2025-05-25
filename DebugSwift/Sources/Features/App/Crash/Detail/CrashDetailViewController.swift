//
//  CrashDetailViewController.swift
//  DebugSwift
//
//  Created by Matheus Gois on 20/12/23.
//

import UIKit

final class CrashDetailViewController: BaseController {
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor.black
        tableView.separatorColor = .darkGray

        return tableView
    }()

    private let viewModel: CrashDetailViewModel

    init(viewModel: CrashDetailViewModel) {
        self.viewModel = viewModel
        super.init()
        setupTabBar()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
        setupShare()
    }

    private func setupTable() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: .cell
        )

        tableView.register(
            MenuSwitchTableViewCell.self,
            forCellReuseIdentifier: MenuSwitchTableViewCell.identifier
        )

        view.backgroundColor = UIColor.black
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupTabBar() {
        title = viewModel.data.type.rawValue
    }

    private func setupShare() {
        addRightBarButton(
            image: .named("square.and.arrow.up", default: "Share")
        ) { [weak self] in
            self?.share()
        }
    }

    private func share() {
        let image = viewModel.data.context.uiImage

        guard let pdf = PDFManager.generatePDF(
            title: title ?? "",
            body: viewModel.getAllValues(),
            image: image,
            logs: viewModel.data.context.consoleOutput
        ) else {
            Debug.print("Failure in create PDF")
            return
        }

        guard let fileURL = PDFManager.savePDFData(
            pdf,
            fileName: "Crash-\(UUID().uuidString).pdf"
        ) else {
            Debug.print("Failure to save PDF")
            return
        }

        let activity = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )

        if let popover = activity.popoverPresentationController {
            popover.sourceView = tableView
            popover.permittedArrowDirections = .up
        }
        present(activity, animated: true, completion: nil)
    }
}

extension CrashDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in _: UITableView) -> Int {
        Features.allCases.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfItems(section: section)
    }

    func tableView(
        _: UITableView,
        heightForHeaderInSection _: Int
    ) -> CGFloat {
        20.0
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let feature = Features(rawValue: indexPath.section)

        let data = viewModel.dataSourceForItem(indexPath)
        let cell = tableView.dequeueReusableCell(
            withIdentifier: .cell,
            for: indexPath
        )
        cell.setup(
            title: data?.title ?? "",
            subtitle: feature != .details ? data?.detail : nil,
            description: feature == .details ? data?.detail : nil,
            image: feature == .context ? .named("chevron.right", default: ">") : nil,
            scale: feature == .stackTrace ? 0.7 : 1
        )
        return cell
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        Features(rawValue: indexPath.section)?.heightForRow ?? .zero
    }

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        Features(rawValue: section)?.title
    }

    func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
        .init()
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        20
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard Features(rawValue: indexPath.section) == .context else { return }

        if
            indexPath.row == .zero,
            let image = viewModel.data.context.uiImage {
            let controller = SnapshotViewController(image: image)
            navigationController?.pushViewController(controller, animated: true)
        } else {
            let output: String

            if indexPath.row == 1, !viewModel.data.context.consoleOutput.isEmpty {
                output = viewModel.data.context.consoleOutput
            } else {
                output = viewModel.data.context.errorOutput
            }

            let controller = LogsViewController(text: output)
            navigationController?.pushViewController(controller, animated: true)
        }
    }
}

extension CrashDetailViewController {
    @MainActor
    enum Features: Int, CaseIterable {
        case details
        case context
        case stackTrace

        var title: String {
            switch self {
            case .details:
                return "Details"
            case .context:
                return "Context"
            case .stackTrace:
                return "Stack Trace"
            }
        }

        var heightForRow: CGFloat {
            switch self {
            case .details:
                return -1 // UITableView interprets -1 as automatic dimension
            case .context:
                return 80
            case .stackTrace:
                return -1 // UITableView interprets -1 as automatic dimension
            }
        }
    }
}
