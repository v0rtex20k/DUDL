//
//  Scribble.swift
//  DUDL
//
//  Created by Victor on 1/27/24.
//

import Foundation
import SwiftUI

struct Scribble: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let offset: CGFloat = CGFloat(rect.size.width) / 10
        let width = rect.size.width
        let height = rect.size.height
        path.move(to: CGPoint(x: 0.15*width - offset, y: 0.67897*height))
        path.addCurve(to: CGPoint(x: 0.78826*width - offset , y: 0.22168*height), control1: CGPoint(x: 0.49946*width - offset, y: 0.29173*height), control2: CGPoint(x: 0.71221*width - offset, y: 0.1393*height))
        path.addCurve(to: CGPoint(x: 0.47392*width - offset, y: 0.8977*height), control1: CGPoint(x: 0.90234*width - offset, y: 0.34525*height), control2: CGPoint(x: 0.37779*width - offset, y: 0.80728*height))
        path.addCurve(to: CGPoint(x: 0.95289*width - offset, y: 0.62055*height), control1: CGPoint(x: 0.57004*width - offset, y: 0.98813*height), control2: CGPoint(x: 0.8498*width - offset, y: 0.5786*height))
        path.addCurve(to: CGPoint(x: 0.87028*width - offset, y: 0.94999*height), control1: CGPoint(x: 1.05599*width - offset, y: 0.6625*height), control2: CGPoint(x: 0.80576*width - offset, y: 0.90861*height))
        path.addCurve(to: CGPoint(x: 1.02828*width - offset, y: 0.87637*height), control1: CGPoint(x: 0.91329*width - offset, y: 0.97757*height), control2: CGPoint(x: 0.96596*width - offset, y: 0.95303*height))
        return path
    }
}
