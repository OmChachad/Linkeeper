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

        if let inputItems = extensionContext.inputItems as? [NSExtensionItem] {
            for inputItem in inputItems {
                if let attachments = inputItem.attachments {
                    for itemProvider in attachments {
                        if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                            itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier, completionHandler: onLoadURL)
                            return
                        } else if itemProvider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                            itemProvider.loadItem(forTypeIdentifier: UTType.text.identifier, completionHandler: onLoadText)
                            return
                        }
                    }
                }
            }
            
            // If no URL or text found, show error.
            presentErrorAlert()
        }
    }
    
    func onLoadURL(data: NSSecureCoding?, error: Error?) {
        if let url = data as? URL {
            presentAddBookmarkView(url: url)
        } else {
            presentErrorAlert()
        }
    }
    
    func onLoadText(data: NSSecureCoding?, error: Error?) {
        if let text = data as? String {
            // Use NSDataDetector to find URLs in the text
            let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

            if let firstMatch = matches?.first, let range = Range(firstMatch.range, in: text) {
                let urlString = String(text[range])
                if let url = URL(string: urlString) {
                    presentAddBookmarkView(url: url)
                    return
                }
            }
        }
        
        presentErrorAlert()
    }
    
    func presentAddBookmarkView(url: URL) {
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
    }
    
    func close(_ isSuccess: Bool) {
        extensionContext?.completeRequest(returningItems: [])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func presentErrorAlert() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "An error occurred",
                                          message: "Could not extract link.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                self.close(false)
            })
            self.present(alert, animated: true, completion: nil)
        }
    }
}
