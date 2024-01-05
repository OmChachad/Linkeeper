//
//  ShareViewController.swift
//  AddBookmarkSheet
//
//  Created by Om Chachad on 13/07/23.
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
        var urlString = ""
        
        #if targetEnvironment(macCatalyst)
            let data = data as? Data
            if let data, let absoluteString = String(data: data, encoding: .utf8) {
                urlString = absoluteString
            }
        #else
            if let url = data as? URL {
                urlString = url.absoluteString
            }
        #endif
        
        DispatchQueue.main.async {
            let dataController = DataController.shared
            let managedObjectContext = dataController.persistentCloudKitContainer.viewContext
            let swiftUIView = AddBookmarkView(urlString: urlString, onComplete: self.close)
                .environment(\.managedObjectContext, managedObjectContext)
                .navigationViewStyle(.stack)
            
            let hostingController = UIHostingController(rootView: swiftUIView)
            self.addChild(hostingController)
            self.view.addSubview(hostingController.view)
            
            #if targetEnvironment(macCatalyst)
            hostingController.view.layer.cornerRadius = 10
            hostingController.view.layer.cornerCurve = .continuous
            hostingController.view.layer.masksToBounds = true
            #endif
            hostingController.view.frame = self.view.bounds
            hostingController.didMove(toParent: self)
            
        }
    }
    
    func close(_ isSuccess: Bool) {
        extensionContext?.completeRequest(returningItems: [])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}
