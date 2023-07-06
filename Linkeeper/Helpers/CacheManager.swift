//
//  CacheManager.swift
//  Linkeeper
//
//  Created by Om Chachad on 27/05/22.
//

import Foundation
import SwiftUI
import LinkPresentation

struct cachedPreview: Codable {
    var imageData: Data?
    var previewState: PreviewType
    
    init(image: UIImage, preview: PreviewType) {
        self.imageData = image.jpegData(compressionQuality: 0.1)
        self.previewState = preview
    }
    
    var image: Image? {
        if let data = imageData, let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        
        return Image("ClassicIconImage")
    }
}

class CacheManager {
    static let instance = CacheManager()
    private init() { }
    
    func add(preview: cachedPreview, id: UUID) {
        if let path = getPath(for: id) {
            if let encodedPreview = try? JSONEncoder().encode(preview) {
                try? encodedPreview.write(to: path)
            }
        }
    }
    
    func remove(id: UUID) {
        if let path = getPath(for: id), FileManager.default.fileExists(atPath: path.path) {
            try? FileManager.default.removeItem(atPath: path.absoluteString)
        }
    }
    
    func get(id: UUID) -> cachedPreview? {
        if let path = getPath(for: id), FileManager.default.fileExists(atPath: path.path), let data = try? Data(contentsOf: path), let cachedPreview = try? JSONDecoder().decode(cachedPreview.self, from: data) {
                return cachedPreview
        }
        return nil
    }
    
    func getPath(for id: UUID) -> URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent(id.uuidString)
    }
}

class CacheModel: ObservableObject {
    @Published var image: cachedPreview?
    let manager = CacheManager.instance
    
    init() { }
    
    func saveToCache(image: UIImage, preview: PreviewType, bookmark: Bookmark) {
        if manager.get(id: bookmark.id ?? UUID()) == nil {
            manager.add(preview: cachedPreview(image: image, preview: preview), id: bookmark.id ?? UUID())
        }
    }
    
    func removeImageFor(bookmark: Bookmark){
        manager.remove (id: bookmark.id ?? UUID())
    }
    
    func getImageFor(bookmark: Bookmark) {
        image = manager.get(id: bookmark.id ?? UUID())
    }
}

enum PreviewType: Codable {
    case loading
    case thumbnail
    case icon
    case firstLetter
}
