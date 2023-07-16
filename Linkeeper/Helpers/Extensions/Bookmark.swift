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
        UIPasteboard.general.url = self.wrappedURL
    }
    
    @MainActor
    func cachedImage(saveTo preview: Binding<cachedPreview?>) {
        let cacheManager = CacheManager.instance
        let bookmarkID = self.id ?? UUID()
        
        if let cachedPreview = cacheManager.get(id: bookmarkID) {
            preview.wrappedValue = cachedPreview
        } else {
            Task {
                let metadata = try? await startFetchingMetadata(for: self.wrappedURL, fetchSubresources: true, timeout: 15)
                if let metadata = metadata {
                    if let imageProvider = metadata.imageProvider ?? metadata.iconProvider {
                        let imageType: PreviewType = metadata.imageProvider != nil ? .thumbnail : .icon
                        imageProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                            guard error == nil else { return }
                            if let image = image as? UIImage {
                                cacheManager.add(preview: cachedPreview(image: image, preview: imageType), id: bookmarkID)
                                preview.wrappedValue = cachedPreview(image: image, preview: imageType)
                            }
                        }
                    }
                }
                
                
                if preview.wrappedValue == nil {
                    preview.wrappedValue = cachedPreview(image: UIImage(), preview: .firstLetter)
                }
            }
        }
    }
}
