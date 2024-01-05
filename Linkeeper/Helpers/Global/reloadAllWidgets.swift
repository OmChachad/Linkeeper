//
//  reloadAllWidgets.swift
//  Linkeeper
//
//  Created by Om Chachad on 05/01/24.
//

#if canImport(WidgetKit)
import WidgetKit

func reloadAllWidgets() {
    if #available(iOS 17.0, *) {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
#endif
