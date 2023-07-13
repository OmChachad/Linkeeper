//
//  DraggableBookmark.swift
//  Linkeeper
//
//  Created by Om Chachad on 29/06/23.
//

import Foundation
import CoreTransferable
import UniformTypeIdentifiers

struct DraggableBookmark: Codable {
    let id: UUID
    let title: String
    let url: URL
    let notes: String
    let dateAdded: Date
    let isFavorited: Bool
    
    var bookmark: Bookmark? {
        try? BookmarksManager.shared.findBookmark(withId: self.id)
    }
}

@available(iOS 16.0, *)
extension DraggableBookmark: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .draggableBookmark)
        ProxyRepresentation(exporting: \.url.absoluteString)
    }
}

extension UTType {
    static var draggableBookmark: UTType = UTType(exportedAs: "org.starlightapps.Linkeeper.bookmark")
}
