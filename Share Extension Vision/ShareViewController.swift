//
//  ShareViewController.swift
//  Share Extension Vision
//
//  Created by Om Chachad on 04/03/24.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers


class ShareViewController: UIViewController {
    // in ShareViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let extensionContext = self.extensionContext else { return }

        if let inputItem = extensionContext.inputItems.first as? NSExtensionItem,
           let itemProvider = inputItem.attachments?.first {
            if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier,completionHandler: onLoadURL)
            }
        }
    }
    
    func onLoadURL(data: NSSecureCoding?, error: Error?) {
        if let url = data as? URL {
            DispatchQueue.main.async {
                let dataController = DataController.shared
                let managedObjectContext = dataController.persistentCloudKitContainer.viewContext
                let swiftUIView = AddBookmarkView(urlString: url.absoluteString, onComplete: self.close)
                    .environment(\.managedObjectContext, managedObjectContext)
                    .navigationViewStyle(.stack)
                
                let hostingController = UIHostingController(rootView: swiftUIView)
                self.addChild(hostingController)
                self.view.addSubview(hostingController.view)
                hostingController.view.frame = CGRectMake(0, 0, 600, 650)
                hostingController.didMove(toParent: self)
            }
        } else {
            self.close(false)
        }
    }
    
    func close(_ isSuccess: Bool) {
        extensionContext?.completeRequest(returningItems: [])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}
