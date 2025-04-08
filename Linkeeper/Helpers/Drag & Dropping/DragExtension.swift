//
//  DragExtension.swift
//  Linkeeper
//
//  Created by Om Chachad on 29/06/23.
//

import Foundation
import SwiftUI

extension View {
    func draggable(_ bookmark: Bookmark) -> some View {
        Group {
            if #available(iOS 16.0, macOS 13.0, *) {
                self
                    .draggable(bookmark.draggable)
            } else {
                self
                    .onDrag { NSItemProvider(object: bookmark.wrappedURL as NSURL) }
            }
        }
    }
    
//    func draggable(_ folder: Folder) -> some View {
//        Group {
//            if #available(iOS 16.0, macOS 13.0, *) {
//                self
//                    .draggable(folder.draggable)
//            } else {
//                self
//                    .onDrag {
//                        NSItemProvider(object: folder.wrappedUUID as NSString)
//                    }
//            }
//        }
//    }
}
