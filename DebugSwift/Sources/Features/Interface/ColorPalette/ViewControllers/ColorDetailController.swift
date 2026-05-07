//
//  ColorDetailController.swift
//  DebugSwift
//
//  Detail screen for a single extracted color: components, usage,
//  accessibility, color-blindness preview, sibling colors, export snippet.
//

import UIKit

final class ColorDetailController: BaseController {

    private let color: ColorInfo
    private let palette: ColorPaletteSnapshot

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        return stack
    }()

    init(color: ColorInfo, palette: ColorPaletteSnapshot) {
        self.color = color
        self.palette = palette
        super.init()
        title = color.name ?? color.hex
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        buildContent()
    }

    private func buildContent() {
        stack.addArrangedSubview(makeSwatchView())

        let infoCard = makeCard(title: "Color Information")
        appendRows(into: infoCard.body, rows: [
            ("Hex", color.hex),
            ("RGB", color.rgbString),
            ("HSB", color.hsbString),
            ("CMYK", color.cmykString),
            ("Alpha", String(format: "%.2f", Double(color.alpha)))
        ])
        stack.addArrangedSubview(infoCard.container)

        stack.addArrangedSubview(makeUsageCard())
        stack.addArrangedSubview(makeAccessibilityCard())
        stack.addArrangedSubview(makeColorBlindnessCard())

        if let group = palette.groups.first(where: { $0.colors.contains(where: { $0.id == color.id }) }),
           group.colors.count > 1 {
            stack.addArrangedSubview(makeSimilarColorsCard(group: group))
        }

        stack.addArrangedSubview(makeExportCard())
    }

    // MARK: - Sections

    private func makeSwatchView() -> UIView {
        let container = UIView()
        container.backgroundColor = color.color
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 0.5
        container.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        container.heightAnchor.constraint(equalToConstant: 180).isActive = true

        let label = UILabel()
        label.text = color.hex
        label.font = .monospacedSystemFont(ofSize: 28, weight: .bold)
        label.textColor = bestContrastColor(against: color.color)
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }

    private func makeUsageCard() -> UIView {
        let card = makeCard(title: "Usage")
        card.body.addArrangedSubview(makeRow(
            title: "Used",
            value: "\(color.usageCount) time\(color.usageCount == 1 ? "" : "s")"
        ))

        let propertyCounts = Dictionary(grouping: color.locations, by: { $0.property })
            .mapValues { $0.count }
        for (property, count) in propertyCounts.sorted(by: { $0.value > $1.value }) {
            card.body.addArrangedSubview(makeRow(title: property.displayName, value: "\(count)"))
        }

        let breakdown = color.componentBreakdown.prefix(5)
        if !breakdown.isEmpty {
            let header = UILabel()
            header.text = "Components"
            header.font = .systemFont(ofSize: 13, weight: .medium)
            header.textColor = .lightGray
            card.body.addArrangedSubview(header)
            for entry in breakdown {
                card.body.addArrangedSubview(makeRow(title: "  \(entry.className)", value: "\(entry.count)"))
            }
        }
        return card.container
    }

    private func makeAccessibilityCard() -> UIView {
        let card = makeCard(title: "Accessibility")

        let onWhite = ColorPaletteAnalyzer.contrastRatio(color.color, .white)
        let onBlack = ColorPaletteAnalyzer.contrastRatio(color.color, .black)

        card.body.addArrangedSubview(makeRow(
            title: "Contrast on white",
            value: String(format: "%.1f:1  %@", Double(onWhite), ColorPaletteAnalyzer.wcagLevel(forContrast: onWhite))
        ))
        card.body.addArrangedSubview(makeRow(
            title: "Contrast on black",
            value: String(format: "%.1f:1  %@", Double(onBlack), ColorPaletteAnalyzer.wcagLevel(forContrast: onBlack))
        ))

        let friendly = ColorPaletteAnalyzer.isColorBlindFriendly(color.color)
        card.body.addArrangedSubview(makeRow(
            title: "Color-blind safe",
            value: friendly ? "Likely safe" : "May be difficult"
        ))
        return card.container
    }

    private func makeColorBlindnessCard() -> UIView {
        let card = makeCard(title: "Color Blindness Preview")

        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = 8

        for type in ColorBlindnessType.allCases {
            let column = UIStackView()
            column.axis = .vertical
            column.alignment = .center
            column.spacing = 4

            let swatch = UIView()
            swatch.backgroundColor = ColorPaletteAnalyzer.simulate(color.color, type: type)
            swatch.layer.cornerRadius = 6
            swatch.heightAnchor.constraint(equalToConstant: 44).isActive = true
            swatch.widthAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true

            let label = UILabel()
            label.text = type.rawValue.capitalized
            label.font = .systemFont(ofSize: 11)
            label.textColor = .lightGray
            label.textAlignment = .center
            label.numberOfLines = 0

            column.addArrangedSubview(swatch)
            column.addArrangedSubview(label)
            row.addArrangedSubview(column)
        }
        card.body.addArrangedSubview(row)
        return card.container
    }

    private func makeSimilarColorsCard(group: ColorGroup) -> UIView {
        let card = makeCard(title: "Similar Colors in Group")
        for similar in group.colors where similar.id != color.id {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 12
            row.alignment = .center

            let swatch = UIView()
            swatch.backgroundColor = similar.color
            swatch.layer.cornerRadius = 6
            swatch.widthAnchor.constraint(equalToConstant: 32).isActive = true
            swatch.heightAnchor.constraint(equalToConstant: 32).isActive = true

            let label = UILabel()
            let dist = ColorPaletteAnalyzer.deltaE2000(color.color, similar.color)
            label.text = "\(similar.hex) — \(similar.usageCount)× — ΔE\(String(format: "%.1f", Double(dist)))"
            label.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
            label.textColor = .white

            row.addArrangedSubview(swatch)
            row.addArrangedSubview(label)
            card.body.addArrangedSubview(row)
        }
        return card.container
    }

    private func makeExportCard() -> UIView {
        let card = makeCard(title: "Swift Snippet")

        let snippet = ColorPaletteExporter.swiftSnippet(for: color)
        let textView = UITextView()
        textView.text = snippet
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = .white
        textView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        let copyButton = UIButton(type: .system)
        copyButton.setTitle("Copy", for: .normal)
        copyButton.setTitleColor(.white, for: .normal)
        copyButton.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        copyButton.layer.cornerRadius = 8
        copyButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        copyButton.addTarget(self, action: #selector(copySnippet), for: .touchUpInside)

        card.body.addArrangedSubview(textView)
        card.body.addArrangedSubview(copyButton)
        return card.container
    }

    // MARK: - UI helpers

    private struct Card {
        let container: UIView
        let body: UIStackView
    }

    private func makeCard(title: String) -> Card {
        let container = UIView()
        container.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        container.layer.cornerRadius = 12
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .white

        let body = UIStackView()
        body.axis = .vertical
        body.spacing = 8

        let outer = UIStackView(arrangedSubviews: [titleLabel, body])
        outer.axis = .vertical
        outer.spacing = 12
        outer.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(outer)
        NSLayoutConstraint.activate([
            outer.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            outer.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            outer.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            outer.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14)
        ])
        return Card(container: container, body: body)
    }

    private func appendRows(into stack: UIStackView, rows: [(String, String)]) {
        for (title, value) in rows {
            stack.addArrangedSubview(makeRow(title: title, value: value))
        }
    }

    private func makeRow(title: String, value: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13)
        titleLabel.textColor = .lightGray
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        valueLabel.textColor = .white
        valueLabel.textAlignment = .right
        valueLabel.lineBreakMode = .byTruncatingMiddle

        let row = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        row.axis = .horizontal
        row.spacing = 8
        return row
    }

    private func bestContrastColor(against color: UIColor) -> UIColor {
        let onWhite = ColorPaletteAnalyzer.contrastRatio(color, .white)
        let onBlack = ColorPaletteAnalyzer.contrastRatio(color, .black)
        return onWhite > onBlack ? .white : .black
    }

    @objc private func copySnippet() {
        UIPasteboard.general.string = ColorPaletteExporter.swiftSnippet(for: color)
        let alert = UIAlertController(title: "Copied", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
