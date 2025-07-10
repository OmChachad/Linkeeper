//
//  DropExtension.swift
//  Linkeeper
//
//  Created by Om Chachad on 29/06/23.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

extension View {
    func dropDestination(isTargeted: Binding<Bool> = .constant(true), onDrop dropAction: @escaping (Bookmark?, URL) -> Void) -> some View {
        Group {
            if #available(iOS 16.0, macOS 13.0, *) {
                self
                    .dropDestination(for: BookmarkDropItem.self) { items, _ in
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
                    } isTargeted: { targetStatus in
                        isTargeted.wrappedValue = targetStatus
                    }
            } else {
                self
                    .onDrop(of: [UTType.url, UTType.bookmark, UTType.urlBookmarkData], isTargeted: isTargeted) { providers in
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
    
//    func folderDropDestination(isTargeted: Binding<Bool> = .constant(true), onDrop dropAction: @escaping (Folder) -> Void) -> some View {
//        Group {
//            if #available(iOS 16.0, macOS 13.0, *) {
//                self
//                    .dropDestination(for: FolderDropItem.self) { items, _ in
//                        var successStatus = true
//                        
//                        items.forEach { droppedItem in
//                            if let droppedFolder = droppedItem.folder?.folder {
//                                dropAction(droppedFolder)
//                            } else {
//                                successStatus = false
//                            }
//                        }
//                        return successStatus
//                    } isTargeted: { targetStatus in
//                        isTargeted.wrappedValue = targetStatus
//                    }
//            } else {
//                self
//                    .onDrop(of: [UTType.text], isTargeted: isTargeted) { providers in
//                        var successStatus = true
//                        
//                        providers.forEach { provider in
//                            
//                            _ = provider.loadObject(ofClass: String.self) { folderID, _ in
//                                if let folderID, let folderUUID = UUID(uuidString: folderID) {
//                                    dropAction(FoldersManager.shared.findFolder(withId: folderUUID))
//                                } else {
//                                    successStatus = false
//                                }
//                            }
//                        }
//                        return successStatus
//                    }
//            }
//        }
//    }
}
