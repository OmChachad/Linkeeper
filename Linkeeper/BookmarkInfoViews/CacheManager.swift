//
//  CacheManager.swift
//  Linkeeper
//
//  Created by Om Chachad on 27/05/22.
//

import Foundation
import SwiftUI
import LinkPresentation

class cachedPreview {
    var value: UIImage
    var previewState: PreviewType
    
    init(image: UIImage, preview: PreviewType) {
        self.value = image
        self.previewState = preview
    }
}

class CacheManager {
    static let instance = CacheManager()
    private init() { }
    
    var imageCache: NSCache<NSString, cachedPreview> = {
        let cache = NSCache<NSString, cachedPreview>()
        //cache.countLimit = 100
        //cache.totalCostLimit = 1024 * 1024 * 10 // 100mb - not sure if this is right
        return cache
    }()
    
    func add(preview: cachedPreview, name: String) {
        imageCache.setObject(preview, forKey: name as NSString)
        print("Added to cache!")
    }
    
    func remove(name: String) {
        imageCache.removeObject(forKey:name as NSString)
        print("Removed from cache!")
    }
    
    func get(name: String) -> cachedPreview? {
        return imageCache.object(forKey: name as NSString)
    }
}

class CacheModel: ObservableObject {
    @Published var image: cachedPreview?
    let manager = CacheManager.instance
    
    init() { }
    
    func saveToCache(image: UIImage, preview: PreviewType, bookmark: Bookmark) {
        if manager.get(name: bookmark.id!.uuidString) == nil {
            manager.add(preview: cachedPreview(image: image, preview: preview), name: bookmark.id!.uuidString)
        }
    }
    
    func removeImageFor(bookmark: Bookmark){
        manager.remove (name: bookmark.id!.uuidString)
    }
    
    func getImageFor(bookmark: Bookmark) {
        image = manager.get(name: bookmark.id!.uuidString)
    }
}

enum PreviewType {
    case loading
    case thumbnail
    case icon
    case firstLetter
}
