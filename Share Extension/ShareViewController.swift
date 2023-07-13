//
//  ShareViewController.swift
//  AddBookmarkSheet
//
//  Created by Om Chachad on 13/07/23.
//

import SwiftUI
import UIKit

import SwiftUI
import UIKit
import UniformTypeIdentifiers


class ShareViewController: UIViewController {
    @IBOutlet var container: UIView!
    
    // in ShareViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let extensionContext = self.extensionContext else { return }

        if let inputItem = extensionContext.inputItems.first as? NSExtensionItem,
           let itemProvider = inputItem.attachments?.first,
           itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, error in
                if let url = item as? URL {
                    DispatchQueue.main.async {
                        let dataController = DataController.shared
                        let swiftUIView = AddBookmarkView(urlString: url.absoluteString, onCancel: self.close).environment(\.managedObjectContext, dataController.persistentCloudKitContainer.viewContext)
                        let hostingController = UIHostingController(rootView: swiftUIView)
                        self.addChild(hostingController)
                        self.view.addSubview(hostingController.view)
                        hostingController.view.frame = self.view.bounds
                        hostingController.didMove(toParent: self)
                    }
                }
            }
        }
    }
    
    func close() {
        extensionContext?.completeRequest(returningItems: [])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

