//
//  DisclosureGroup.swift
//  Linkeeper
//
//  Created by Om Chachad on 17/05/23.
//

import Foundation
import SwiftUI

extension DisclosureGroup {
    func expandByDefault(_ isExpanded: Bool) -> some View {
        Group {
            if #available(iOS 16.0, *) {
                self
                    .disclosureGroupStyle(ExpandedByDefault(expandByDefault: isExpanded))
            } else {
                self
            }
        }
    }
}
