//
//  FolderDropItem.swift
//  Linkeeper
//
//  Created by Om Chachad on 17/06/23.
//

import Foundation
import CoreTransferable

@available(iOS 16.0, macOS 13.0, *)
enum FolderDropItem: Codable, Transferable {
    case none
    case folder(DraggableFolder?)
    
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation { .folder($0) }
    }
    
    var folder: DraggableFolder? {
        switch self {
            case .folder(let folder): return folder
            default: return nil
        }
    }
}
