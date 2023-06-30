//
//  DropExtension.swift
//  Linkeeper
//
//  Created by Om Chachad on 29/06/23.
//

import Foundation
import SwiftUI

extension View {
    func dropDestination(onDrop dropAction: @escaping (Bookmark?, URL) -> Void) -> some View {
        Group {
            if #available(iOS 16.0, *) {
                self
                    .dropDestination(for: DropItem.self) { items, _ in
                        items.forEach { droppedItem in
                            if let droppedBookmark = droppedItem.bookmark {
                                print("DropAction: Dropping Bookmark")
                                dropAction(droppedBookmark.bookmark, droppedBookmark.url)
                            } else if let url = droppedItem.url {
                                if BookmarksManager.shared.getAllBookmarks().first(where: {$0.url == url.absoluteString}) == nil {
                                    print("DropAction: Dropping URL")
                                    dropAction(nil, url)
                                }
                            }
                        }
                        
                        return true
                    }
            } else {
                self
                    .onDrop(of: ["public.url"], isTargeted: nil) { providers in
                        providers.forEach { provider in
                            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                                if let url {
                                    if BookmarksManager.shared.getAllBookmarks().first(where: {$0.url == url.absoluteString}) == nil {
                                        dropAction(nil, url)
                                    }
                                }
                            }
                        }
                        return true
                    }
            }
        }
    }
}
