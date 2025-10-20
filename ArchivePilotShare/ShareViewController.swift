import UIKit
import SwiftUI
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private var hostingController: UIHostingController<AnyView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        handleInputItems()
    }

    private func handleInputItems() {
        guard let extensionContext = extensionContext else { return }
        guard let item = extensionContext.inputItems.first as? NSExtensionItem,
              let provider = item.attachments?.first else { return }

        let types: [UTType] = [.pdf, .image, .plainText, .data]
        for type in types {
            if provider.hasItemConformingToTypeIdentifier(type.identifier) {
                provider.loadItem(forTypeIdentifier: type.identifier, options: nil) { item, error in
                    if let error {
                        DispatchQueue.main.async {
                            self.presentError(error)
                        }
                        return
                    }
                    guard let url = item as? URL else { return }
                    DispatchQueue.main.async {
                        self.presentShareView(url: url, type: type, context: extensionContext)
                    }
                }
                break
            }
        }
    }

    private func presentShareView(url: URL, type: UTType, context: NSExtensionContext) {
        let shareView = ShareView(itemURL: url, itemType: type)
            .environment(\.extensionContext, context)
        let hosting = UIHostingController(rootView: AnyView(shareView))
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hosting.didMove(toParent: self)
        hostingController = hosting
    }

    private func presentError(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default) { _ in
            self.extensionContext?.cancelRequest(withError: error)
        })
        present(alert, animated: true)
    }
}
