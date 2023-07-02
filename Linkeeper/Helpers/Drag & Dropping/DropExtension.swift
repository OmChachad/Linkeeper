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
                        var successStatus = true
                        
                        items.forEach { droppedItem in
                            if let droppedBookmark = droppedItem.bookmark {
                                dropAction(droppedBookmark.bookmark, droppedBookmark.url)
                            } else if let url = droppedItem.url {
                                if BookmarksManager.shared.getAllBookmarks().first(where: {$0.url == url.absoluteString}) == nil {
                                    dropAction(nil, url)
                                } else {
                                    successStatus = false
                                }
                            } else {
                                successStatus = false
                            }
                        }
                        return successStatus
                    }
            } else {
                self
                    .onDrop(of: ["public.url"], isTargeted: nil) { providers in
                        var successStatus = true
                        
                        providers.forEach { provider in
                            
                            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                                if let url {
                                    if BookmarksManager.shared.getAllBookmarks().first(where: {$0.url == url.absoluteString}) == nil {
                                        dropAction(nil, url)
                                    } else {
                                        successStatus = false
                                    }
                                } else {
                                    successStatus = false
                                }
                            }
                        }
                        return successStatus
                    }
            }
        }
    }
}
