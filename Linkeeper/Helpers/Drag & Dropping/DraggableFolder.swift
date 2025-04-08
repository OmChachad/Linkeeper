//
//  DraggableFolder.swift
//  Linkeeper
//
//  Created by Om Chachad on 17/06/23.
//

import Foundation
import CoreTransferable
import UniformTypeIdentifiers

struct DraggableFolder: Codable {
    let id: UUID
    let title: String
    let symbol: String
    let index: Int
    let isPinned: Bool
    
    var folder: Folder? {
        FoldersManager.shared.findFolder(withId: self.id)
    }
}

@available(iOS 16.0, macOS 13.0, *)
extension DraggableFolder: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .draggableFolder)
    }
}

extension UTType {
    static var draggableFolder: UTType = UTType(exportedAs: "org.starlightapps.Linkeeper.folder")
}
