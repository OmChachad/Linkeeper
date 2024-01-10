//
//  DropItem.swift
//  Linkeeper
//
//  Created by Om Chachad on 30/06/23.
//

import Foundation
import CoreTransferable

@available(iOS 16.0, macOS 13.0, *)
enum DropItem: Codable, Transferable {
    case none
    case bookmark(DraggableBookmark?)
    case url(URL)
    
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation { .url($0) }
        ProxyRepresentation { .bookmark($0) }
    }
    
    var bookmark: DraggableBookmark? {
        switch self {
            case .bookmark(let bookmark): return bookmark
            default: return nil
        }
    }
    
    var url: URL? {
        switch self {
            case.url(let url): return url
            default: return nil
        }
    }
}
