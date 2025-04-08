//
//  Bookmark.swift
//  Linkeeper
//
//  Created by Om Chachad on 06/07/23.
//

import Foundation
import SwiftUI

extension Bookmark {
    func copyURL() {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([self.wrappedURL as NSPasteboardWriting])
        #else
        UIPasteboard.general.url = self.wrappedURL
        #endif
    }
    
    @MainActor
    func cachedImage(saveTo preview: Binding<cachedPreview?>) {
        let cacheManager = CacheManager.instance
        
        if let cachedPreview = cacheManager.get(for: self) {
            withAnimation {
                preview.wrappedValue = cachedPreview
            }
        } else {
            // Using detached task to perform fetching in background
            Task.detached(priority: .userInitiated) {
                await self.cachePreviewInto(preview)
                
                if preview.wrappedValue == nil {
                    withAnimation {
                        preview.wrappedValue = cachedPreview(image: UIImage(), preview: .firstLetter)
                    }
                }
            }
        }
    }
    
    func cachePreviewInto(_ preview: Binding<cachedPreview?>) async {
        let cacheManager = CacheManager.instance
        
        let metadata = try? await startFetchingMetadata(for: self.wrappedURL, fetchSubresources: true, timeout: 15)
        if let metadata = metadata {
            if let imageProvider = metadata.imageProvider ?? metadata.iconProvider {
                let imageType: PreviewType = metadata.imageProvider != nil ? .thumbnail : .icon
                imageProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                    guard error == nil else { return }
                    if let image = image as? UIImage {
                        // Ensure UI updates happen on main thread
                                                Task { @MainActor in
                                                    cacheManager.add(preview: cachedPreview(image: image, preview: imageType), for: self)
                                                    preview.wrappedValue = cachedPreview(image: image, preview: imageType)
                                                }
                    }
                }
            }
        }
    }
}
