//
//  ShareViewController.swift
//  Share Extension Mac
//
//  Created by Om Chachad on 12/01/24.
//

import Cocoa
import UniformTypeIdentifiers
import SwiftUI

class ShareViewController: NSViewController {
    
    override func loadView() {
        super.loadView()
        
        guard let extensionContext = self.extensionContext else { return }

        if let inputItem = extensionContext.inputItems.first as? NSExtensionItem,
           let itemProvider = inputItem.attachments?.first {
            if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier, completionHandler: onLoadURL)
            }
        }
    }
    
    func onLoadURL(data: NSSecureCoding?, error: Error?) {
        if let data = data as? Data, let urlString = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                let dataController = DataController.shared
                let managedObjectContext = dataController.persistentCloudKitContainer.viewContext
                let swiftUIView = AddBookmarkView(urlString: urlString, onComplete: self.close)
                    .environment(\.managedObjectContext, managedObjectContext)
                
                let hostingController = NSHostingController(rootView: swiftUIView)
                self.addChild(hostingController)
                hostingController.view.frame = self.view.bounds
                self.view.addSubview(hostingController.view)
            }
        } else {
            self.cancel(nil)
        }
    }
    
    @IBAction func close(_ isSuccess: Bool) {
        extensionContext?.completeRequest(returningItems: [])
    }
    
    @IBAction func cancel(_ sender: AnyObject?) {
        let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
        self.extensionContext!.cancelRequest(withError: cancelError)
    }
    
}
