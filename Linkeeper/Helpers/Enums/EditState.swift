//
//  EditState.swift
//  Linkeeper
//
//  Created by Om Chachad on 07/01/24.
//

import Foundation
import SwiftUI

#if os(macOS)
enum EditMode {
    case active
    case inactive
    case transient
}

struct EditStateKey: EnvironmentKey {
    static var defaultValue: EditMode = .inactive
}

extension EnvironmentValues {
    var editMode: EditMode {
        get { self[EditStateKey.self] }
        set { self[EditStateKey.self] = newValue }
    }
}
#endif
