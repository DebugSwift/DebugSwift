//
//  MenuViewController.swift
//  HyperionSwift
//
//  Created by Matheus Gois on 02/01/25.
//

import UIKit

protocol MenuDelegate: AnyObject {
    func didSelectMenuItem(_ item: MenuItem)
}

final class MenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let viewBackground: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        return view
    }()

    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(MenuCell.self, forCellReuseIdentifier: "MenuCell")
        tableView.separatorStyle = .none

        return tableView
    }()

    weak var delegate: MenuDelegate?

    required init(delegate: MenuDelegate?) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = .white
        view.addSubview(viewBackground)

        tableView.frame = CGRect(x: view.frame.width / 2, y: 0, width: view.frame.width / 2, height: view.frame.height)

        // Calcula o padding para centralizar o conteúdo verticalmente
        let contentHeight = tableView.contentSize.height
        let topInset = (view.frame.height - contentHeight) / 4

        // Ajusta o contentInset para centralizar o conteúdo
        tableView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)

        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
    }

    @objc
    private func dismissSelf() {
        presentingViewController?.dismiss(animated: true)
    }

    // MARK: - UITableViewDataSource

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return MenuItem.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell", for: indexPath) as! MenuCell
        cell.setup(item: MenuItem.allCases[indexPath.row])
        return cell
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 80
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didSelectMenuItem(MenuItem.allCases[indexPath.row])
    }

    // MARK: - UITableViewDelegate
    // Se precisar de personalizações adicionais, como altura da célula, pode adicionar aqui.
}

class MenuCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(item: MenuItem) {
        imageView?.image = item.image.withRenderingMode(.alwaysTemplate)
        imageView?.tintColor = .black
        textLabel?.text = item.title
    }

    private func setupCell() {
        selectionStyle = .none
    }
}

enum MenuItem: CaseIterable {
    case measurement

    var title: String {
        switch self {
        case .measurement: return "Measurement"
        }
    }

    var image: UIImage {
        switch self {
        case .measurement:
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "ruler")!
            } else {
                return UIImage()
            }
        }
    }
}
