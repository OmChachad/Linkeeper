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

private struct EditModeKey: EnvironmentKey {
    static let defaultValue: EditMode = .inactive
}

extension EnvironmentValues {
    var editMode: EditMode {
        get { self[EditModeKey.self] }
        set { self[EditModeKey.self] = newValue }
    }
}
#endif
