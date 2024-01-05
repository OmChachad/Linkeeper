//
//  reloadAllWidgets.swift
//  Linkeeper
//
//  Created by Om Chachad on 05/01/24.
//

#if canImport(WidgetKit)
import WidgetKit
#endif

func reloadAllWidgets() {
#if canImport(WidgetKit)
    if #available(iOS 17.0, *) {
        WidgetCenter.shared.reloadAllTimelines()
    }
#endif
}
