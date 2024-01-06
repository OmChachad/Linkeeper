//
//  ViewOption.swift
//  Linkeeper
//
//  Created by Om Chachad on 05/01/24.
//

import Foundation
 
enum ViewOption: String, Codable, CaseIterable {
    case grid
    case list
    case table
    
    var iconString: String {
        switch(self) {
        case .grid:
            return "square.grid.2x2"
        case .list:
            return "list.bullet"
        case .table:
            return "table"
        }
    }
    
    var title: String {
        switch(self) {
        case .grid:
            return "Grid"
        case .list:
            return "List"
        case .table:
            return "Table"
        }
    }
}
