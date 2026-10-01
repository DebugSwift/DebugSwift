//
//  LeakView.swift
//  Example
//
//  Created by Assistant on today's date.
//

import SwiftUI

struct LeakView: View {
    @State private var presentingLeak = false

    var body: some View {
        ZStack {
            Color.orange
                .ignoresSafeArea()

            Button("Open leaking view controller") {
                presentingLeak = true
            }
            .foregroundColor(.black)
        }
        // A pushed screen stays alive in SwiftUI's navigation stack, so present it as a sheet
        .sheet(isPresented: $presentingLeak) {
            LeakViewControllerRepresentable()
                .ignoresSafeArea()
        }
    }
}

struct LeakViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> LeakViewController {
        LeakViewController()
    }

    func updateUIViewController(_ uiViewController: LeakViewController, context: Context) {}
}

class LeakViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemOrange

        let imageView = UIImageView(image: UIImage(systemName: "drop.triangle"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .black
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 200),
            imageView.heightAnchor.constraint(equalToConstant: 200),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        DispatchQueue.main.asyncAfter(wallDeadline: .now() + 10) {
            // Leak
            print(self)
        }
    }
}

struct LeakView_Previews: PreviewProvider {
    static var previews: some View {
        LeakView()
    }
}
