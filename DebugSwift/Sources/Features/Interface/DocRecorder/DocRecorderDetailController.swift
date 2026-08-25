//
//  DocRecorderDetailController.swift
//  DebugSwift
//
//  Created by Matheus Gois on 14/05/26.
//

import UIKit

final class DocRecorderDetailController: BaseController {
    private let recording: SavedRecording
    private let storage = RecordingSessionStorage.shared
    private var images: [UIImage] = []

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .black
        return scrollView
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    init(recording: SavedRecording) {
        self.recording = recording
        super.init()
        title = recording.title
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupToolbar()
        loadImages()
    }

    private func setupUI() {
        view.backgroundColor = .black

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
        ])
    }

    private func setupToolbar() {
        let copyAllButton = UIBarButtonItem(
            title: "Copy All",
            style: .plain,
            target: self,
            action: #selector(copyAllImages)
        )
        let shareButton = UIBarButtonItem(
            title: "Share",
            style: .plain,
            target: self,
            action: #selector(shareImages)
        )
        navigationItem.rightBarButtonItems = [shareButton, copyAllButton]
    }

    private func loadImages() {
        images = storage.loadImages(for: recording)

        for (index, image) in images.enumerated() {
            let stepView = createStepView(index: index, image: image)
            stackView.addArrangedSubview(stepView)
        }
    }

    private func createStepView(index: Int, image: UIImage) -> UIView {
        let container = UIView()

        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        let stepLabel = UILabel()
        stepLabel.text = "Step \(index + 1)"
        stepLabel.font = .boldSystemFont(ofSize: 17)
        stepLabel.textColor = .white

        let copyButton = UIButton(type: .system)
        copyButton.setTitle("Copy", for: .normal)
        copyButton.titleLabel?.font = .systemFont(ofSize: 13)
        copyButton.tag = index
        copyButton.addTarget(self, action: #selector(copySingleImage(_:)), for: .touchUpInside)

        headerStack.addArrangedSubview(stepLabel)
        headerStack.addArrangedSubview(UIView())
        headerStack.addArrangedSubview(copyButton)

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let aspectRatio = image.size.height / max(image.size.width, 1)

        container.addSubview(headerStack)
        container.addSubview(imageView)

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: container.topAnchor),
            headerStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            headerStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            imageView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 8),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: aspectRatio),
        ])

        return container
    }

    @objc private func copySingleImage(_ sender: UIButton) {
        guard sender.tag < images.count else { return }
        UIPasteboard.general.image = images[sender.tag]
    }

    @objc private func copyAllImages() {
        guard !images.isEmpty else { return }

        let columns: Int
        switch images.count {
        case 1: columns = 1
        case 2: columns = 2
        default: columns = 3
        }

        let spacing: CGFloat = 20
        let imageWidth = images[0].size.width
        let imageHeight = images[0].size.height

        let rows = Int(ceil(Double(images.count) / Double(columns)))
        let totalWidth = (imageWidth * CGFloat(columns)) + (spacing * CGFloat(columns - 1))
        let totalHeight = (imageHeight * CGFloat(rows)) + (spacing * CGFloat(rows - 1))

        let format = UIGraphicsImageRendererFormat()
        format.scale = images[0].scale

        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: totalWidth, height: totalHeight),
            format: format
        )

        let gridImage = renderer.image { _ in
            for (index, image) in images.enumerated() {
                let row = index / columns
                let col = index % columns

                let x = CGFloat(col) * (imageWidth + spacing)
                let y = CGFloat(row) * (imageHeight + spacing)

                image.draw(at: CGPoint(x: x, y: y))
            }
        }

        UIPasteboard.general.image = gridImage
    }

    @objc private func shareImages() {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DocRecorder-Share-\(UUID().uuidString)", isDirectory: true)

        try? FileManager.default.createDirectory(
            at: tempDirectory, withIntermediateDirectories: true
        )

        var fileURLs: [URL] = []
        for (index, image) in images.enumerated() {
            let fileName = String(format: "screenshot-%03d.png", index + 1)
            let fileURL = tempDirectory.appendingPathComponent(fileName)

            if let pngData = image.pngData() {
                try? pngData.write(to: fileURL)
                fileURLs.append(fileURL)
            }
        }

        let activityVC = UIActivityViewController(
            activityItems: fileURLs,
            applicationActivities: nil
        )

        activityVC.completionWithItemsHandler = { _, _, _, _ in
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(
                x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0
            )
            popover.permittedArrowDirections = []
        }

        present(activityVC, animated: true)
    }
}
