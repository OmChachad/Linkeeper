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
    
    func onLoadText(data: NSSecureCoding?, error: Error?) {
        if let text = data as? String {
            // Use NSDataDetector to find URLs in the text
            let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

            if let firstMatch = matches?.first, let range = Range(firstMatch.range, in: text) {
                let urlString = String(text[range])
                if isLikelyWebURL(urlString) {
                    presentAddBookmarkView(url: urlString)
                    return
                }
            }
        }
        
        presentErrorAlert()
    }
    
    func onLoadURL(data: NSSecureCoding?, error: Error?) {
        if let data = data as? Data, let urlString = String(data: data, encoding: .utf8), isLikelyWebURL(urlString) {
            presentAddBookmarkView(url: urlString)
        } else {
            presentErrorAlert()
        }
    }
    
    func presentAddBookmarkView(url: String) {
        DispatchQueue.main.async {
            let dataController = DataController.shared
            let managedObjectContext = dataController.persistentCloudKitContainer.viewContext
            let swiftUIView = AddBookmarkView(urlString: url, onComplete: self.close)
                .environment(\.managedObjectContext, managedObjectContext)
            
            let hostingController = NSHostingController(rootView: swiftUIView)
            self.addChild(hostingController)
            hostingController.view.frame = self.view.bounds
            self.view.addSubview(hostingController.view)
        }
    }
    
    func isLikelyWebURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else {
            return false
        }

        if let scheme = url.scheme?.lowercased() {
            return scheme == "http" || scheme == "https"
        }

        // No scheme present – assume it's a web URL (like "example.com")
        return true
    }
    
    @IBAction func close(_ isSuccess: Bool) {
        extensionContext?.completeRequest(returningItems: [])
    }
    
    @IBAction func cancel(_ sender: AnyObject?) {
        let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
        self.extensionContext!.cancelRequest(withError: cancelError)
    }
    
    func presentErrorAlert() {
        DispatchQueue.main.async {
            let swiftUIView = VStack {
                Text("An error occurred")
                    .font(.headline)
                
                Text("Could not extract link.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                Divider()
                    
                Button("OK") {
                    self.close(false)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            let hostingController = NSHostingController(rootView: swiftUIView)
            self.addChild(hostingController)
            hostingController.view.frame = self.view.bounds
            self.view.addSubview(hostingController.view)
        }
    }
}
