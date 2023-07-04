//
//  YouTube.swift
//  Linkeeper
//
//  Created by Om Chachad on 08/06/23.
//

import Foundation
import SwiftUI

struct YouTube: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.size.width
        let height = rect.size.height
        path.move(to: CGPoint(x: 0.94848*width, y: 0.19482*height))
        path.addCurve(to: CGPoint(x: width, y: 0.5*height), control1: CGPoint(x: 0.99404*width, y: 0.24194*height), control2: CGPoint(x: width, y: 0.31681*height))
        path.addCurve(to: CGPoint(x: 0.94848*width, y: 0.80518*height), control1: CGPoint(x: width, y: 0.68319*height), control2: CGPoint(x: 0.99404*width, y: 0.75806*height))
        path.addCurve(to: CGPoint(x: 0.5*width, y: 0.85602*height), control1: CGPoint(x: 0.90291*width, y: 0.8523*height), control2: CGPoint(x: 0.85546*width, y: 0.85602*height))
        path.addCurve(to: CGPoint(x: 0.05152*width, y: 0.80518*height), control1: CGPoint(x: 0.14454*width, y: 0.85602*height), control2: CGPoint(x: 0.09709*width, y: 0.8523*height))
        path.addCurve(to: CGPoint(x: 0, y: 0.5*height), control1: CGPoint(x: 0.00596*width, y: 0.75806*height), control2: CGPoint(x: 0, y: 0.68319*height))
        path.addCurve(to: CGPoint(x: 0.05152*width, y: 0.19482*height), control1: CGPoint(x: 0, y: 0.31681*height), control2: CGPoint(x: 0.00596*width, y: 0.24194*height))
        path.addCurve(to: CGPoint(x: 0.5*width, y: 0.14398*height), control1: CGPoint(x: 0.09707*width, y: 0.1477*height), control2: CGPoint(x: 0.14454*width, y: 0.14398*height))
        path.addCurve(to: CGPoint(x: 0.94848*width, y: 0.19482*height), control1: CGPoint(x: 0.85546*width, y: 0.14398*height), control2: CGPoint(x: 0.90291*width, y: 0.1477*height))
        path.closeSubpath()
        path.move(to: CGPoint(x: 0.419*width, y: 0.65088*height))
        path.addLine(to: CGPoint(x: 0.66191*width, y: 0.50769*height))
        path.addLine(to: CGPoint(x: 0.419*width, y: 0.36674*height))
        path.addLine(to: CGPoint(x: 0.419*width, y: 0.65088*height))
        path.closeSubpath()
        return path
    }
}
