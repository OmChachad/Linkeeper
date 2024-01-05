//
//  Bool.swift
//  Linkeeper
//
//  Created by Om Chachad on 05/01/24.
//

import Foundation

extension Bool: Comparable {
    /// This function allows Comprable conformance for Bool
    public static func < (lhs: Bool, rhs: Bool) -> Bool {
        return lhs == false && rhs == true
    }
}
