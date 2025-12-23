//
//  OpenAction.swift
//  Linkeeper
//
//  Created by Om Chachad on 23/12/25.
//

import Foundation

enum OpenAction: String, CaseIterable {
    case openInLinkeeper, askAndOpen, openDirectly
    
    var symbol: String {
        switch(self) {
        case .openDirectly:
            "safari"
        case .askAndOpen:
            "questionmark.square"
        case .openInLinkeeper:
            "bookmark.fill"
        }
    }
    
    var title: String {
        switch(self) {
        case .openDirectly:
            "Open Directly"
        case .askAndOpen:
            "Ask Before Opening"
        case .openInLinkeeper:
            "Open in Linkeeper"
        }
    }
}
