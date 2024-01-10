//
//  macOS Bridge.swift
//  Linkeeper
//
//  Created by Om Chachad on 07/01/24.
//

#if os(macOS)
import Foundation
import Cocoa
import SwiftUI

typealias UIImage = NSImage
typealias UIColor = NSColor

extension Color {
    init(uiColor: UIColor) {
        self.init(nsColor: uiColor)
    }
}
extension Image {
    init(uiImage: UIImage) {
        self.init(nsImage: uiImage)
    }
}

extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        let image = self.copy() as! NSImage
        image.lockFocus()
        color.set()
        let imageRect = NSRect(origin: .zero, size: image.size)
        imageRect.fill(using: .sourceAtop)
        image.unlockFocus()
        return image
    }
}
#endif
