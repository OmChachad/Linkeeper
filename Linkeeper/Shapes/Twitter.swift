//
//  Twitter.swift
//  Linkeeper
//
//  Created by Om Chachad on 08/06/23.
//

import Foundation
import SwiftUI

struct Twitter: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.size.width
        let height = rect.size.height
        path.move(to: CGPoint(x: 1.00119*width, y: 0.20875*height))
        path.addCurve(to: CGPoint(x: 0.88299*width, y: 0.24117*height), control1: CGPoint(x: 0.96424*width, y: 0.22516*height), control2: CGPoint(x: 0.92463*width, y: 0.23617*height))
        path.addCurve(to: CGPoint(x: 0.97346*width, y: 0.12742*height), control1: CGPoint(x: 0.92549*width, y: 0.2157*height), control2: CGPoint(x: 0.95814*width, y: 0.17539*height))
        path.addCurve(to: CGPoint(x: 0.84283*width, y: 0.17727*height), control1: CGPoint(x: 0.93377*width, y: 0.15094*height), control2: CGPoint(x: 0.88963*width, y: 0.16805*height))
        path.addCurve(to: CGPoint(x: 0.69276*width, y: 0.11234*height), control1: CGPoint(x: 0.80533*width, y: 0.13727*height), control2: CGPoint(x: 0.7519*width, y: 0.11234*height))
        path.addCurve(to: CGPoint(x: 0.48706*width, y: 0.31797*height), control1: CGPoint(x: 0.57917*width, y: 0.11234*height), control2: CGPoint(x: 0.48706*width, y: 0.20438*height))
        path.addCurve(to: CGPoint(x: 0.49245*width, y: 0.36484*height), control1: CGPoint(x: 0.48706*width, y: 0.33406*height), control2: CGPoint(x: 0.48893*width, y: 0.34977*height))
        path.addCurve(to: CGPoint(x: 0.06855*width, y: 0.14992*height), control1: CGPoint(x: 0.32152*width, y: 0.35625*height), control2: CGPoint(x: 0.17004*width, y: 0.27437*height))
        path.addCurve(to: CGPoint(x: 0.04074*width, y: 0.25336*height), control1: CGPoint(x: 0.05082*width, y: 0.18039*height), control2: CGPoint(x: 0.04074*width, y: 0.2157*height))
        path.addCurve(to: CGPoint(x: 0.13222*width, y: 0.42461*height), control1: CGPoint(x: 0.04074*width, y: 0.32469*height), control2: CGPoint(x: 0.07699*width, y: 0.38766*height))
        path.addCurve(to: CGPoint(x: 0.03902*width, y: 0.39883*height), control1: CGPoint(x: 0.09847*width, y: 0.42352*height), control2: CGPoint(x: 0.06676*width, y: 0.41422*height))
        path.addCurve(to: CGPoint(x: 0.03902*width, y: 0.40141*height), control1: CGPoint(x: 0.03902*width, y: 0.39969*height), control2: CGPoint(x: 0.03902*width, y: 0.40055*height))
        path.addCurve(to: CGPoint(x: 0.20394*width, y: 0.60312*height), control1: CGPoint(x: 0.03902*width, y: 0.50109*height), control2: CGPoint(x: 0.10996*width, y: 0.58414*height))
        path.addCurve(to: CGPoint(x: 0.1498*width, y: 0.61031*height), control1: CGPoint(x: 0.18675*width, y: 0.60781*height), control2: CGPoint(x: 0.16855*width, y: 0.61031*height))
        path.addCurve(to: CGPoint(x: 0.11105*width, y: 0.60656*height), control1: CGPoint(x: 0.13652*width, y: 0.61031*height), control2: CGPoint(x: 0.12363*width, y: 0.60906*height))
        path.addCurve(to: CGPoint(x: 0.30316*width, y: 0.74945*height), control1: CGPoint(x: 0.1373*width, y: 0.6882*height), control2: CGPoint(x: 0.21324*width, y: 0.74781*height))
        path.addCurve(to: CGPoint(x: 0.04777*width, y: 0.83742*height), control1: CGPoint(x: 0.23285*width, y: 0.80461*height), control2: CGPoint(x: 0.14418*width, y: 0.83742*height))
        path.addCurve(to: CGPoint(x: -0.00121*width, y: 0.83453*height), control1: CGPoint(x: 0.03113*width, y: 0.83742*height), control2: CGPoint(x: 0.0148*width, y: 0.83648*height))
        path.addCurve(to: CGPoint(x: 0.31402*width, y: 0.92695*height), control1: CGPoint(x: 0.08972*width, y: 0.89297*height), control2: CGPoint(x: 0.19785*width, y: 0.92695*height))
        path.addCurve(to: CGPoint(x: 0.89916*width, y: 0.34187*height), control1: CGPoint(x: 0.69229*width, y: 0.92695*height), control2: CGPoint(x: 0.89916*width, y: 0.61359*height))
        path.addCurve(to: CGPoint(x: 0.89861*width, y: 0.31523*height), control1: CGPoint(x: 0.89916*width, y: 0.33297*height), control2: CGPoint(x: 0.89893*width, y: 0.32398*height))
        path.addCurve(to: CGPoint(x: 1.00119*width, y: 0.20875*height), control1: CGPoint(x: 0.93877*width, y: 0.28625*height), control2: CGPoint(x: 0.97361*width, y: 0.25*height))
        path.closeSubpath()
        return path
    }
}
