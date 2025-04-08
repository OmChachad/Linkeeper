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
        #if os(macOS)
        self.imageData = image.tiffRepresentation
        #else
        self.imageData = image.jpegData(compressionQuality: 0.5)
        #endif
        
        self.previewState = preview
    }
    
    var image: Image? {
        if let data = imageData, let uiImage = UIImage(data: data), let compressedImage = uiImage.preparingThumbnail(of: CGSize(width: 300, height: uiImage.size.height * 300 / uiImage.size.width)) {
            return Image(uiImage: compressedImage)
        }
        
        return nil
    }
}

class CacheManager {
    static let instance = CacheManager()
    private init() { }
    
    func add(preview: cachedPreview, for bookmark: Bookmark) {
        add(preview: preview, id: bookmark.id ?? UUID())
    }
    
    func remove(for bookmark: Bookmark) {
        remove(id: bookmark.id ?? UUID())
    }
    
    func get(for bookmark: Bookmark) -> cachedPreview? {
        get(id: bookmark.id ?? UUID())
    }
    
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
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.starlightapps.linkeeper")?.appendingPathComponent(id.uuidString)
    }
    
    /// This function clears out all the cached thumbnails from the cachesDirectory, since the new directory is now accessible by the entire app group to faciliate previews in widgets.
    func clearOutOld() {
        let hasCleared = UserDefaults.standard.bool(forKey: "hasClearedOldDirectory")
        if !hasCleared {
            let bookmarks = BookmarksManager.shared.getAllBookmarks()
            bookmarks.forEach { bookmark in
                if let oldPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent(bookmark.wrappedUUID), FileManager.default.fileExists(atPath: oldPath.path) {
                    try? FileManager.default.removeItem(atPath: oldPath.absoluteString)
                }
            }
            UserDefaults.standard.setValue(true, forKey: "hasClearedOldDirectory")
        }
    }
}

enum PreviewType: Codable {
    case loading
    case thumbnail
    case icon
    case firstLetter
}

#if canImport(AppKit)
import AppKit

extension NSImage {
    func preparingThumbnail(of size: NSSize) -> NSImage? {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        defer { newImage.unlockFocus() }
        
        guard let context = NSGraphicsContext.current?.cgContext else { return nil }
        context.interpolationQuality = .high
        self.draw(in: NSRect(origin: .zero, size: size),
                  from: NSRect(origin: .zero, size: self.size),
                  operation: .copy,
                  fraction: 1.0)
        
        return newImage
    }
}
#endif
