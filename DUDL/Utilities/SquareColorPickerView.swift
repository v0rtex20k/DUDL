//
//  SquareColorPickerView.swift
//  DUDL
//
//  Created by V on 1/30/24.
//

import Foundation
import SwiftUI

struct SquareColorPickerView: View {
    @Binding var colorValue: Color
    var body: some View {
        colorValue
            .cornerRadius(10.0)
            .overlay(RoundedRectangle(cornerRadius: 5.0).stroke(Color.white, style: StrokeStyle(lineWidth: 3)))
            .padding(10)
            .background(AngularGradient(gradient: Gradient(colors: [.red,.yellow,.green,.blue,.purple,.pink]), center:.center).cornerRadius(8.0))
            .overlay(
                ColorPicker("", selection: $colorValue, supportsOpacity: true).labelsHidden().opacity(0.015)
            )
            .aspectRatio(contentMode: .fit)
            .shadow(radius: 5.0)

    }
}

class UIColorWellHelper: NSObject {
    static let helper = UIColorWellHelper()
    var execute: (() -> ())?
    @objc func handler(_ sender: Any) {
        execute?()
    }
}

extension UIColorWell {
    override open func didMoveToSuperview() {
        // ...
        
        // find a button and store handler with it in helper
        if let uiButton = self.subviews.first?.subviews.last as? UIButton {
            UIColorWellHelper.helper.execute = {
                uiButton.sendActions(for: .touchUpInside)
                
            }
        }
    }
}
