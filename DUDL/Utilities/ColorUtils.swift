//
//  ColorUtils.swift
//  DUDL
//
//  Created by V on 1/30/24.
//

import Foundation
import SwiftUI

extension Color {
    static func random(from colors: [Color]) -> Color {
        return colors.randomElement() ?? Color.green
    }
}

extension View {
    func apply<V: View>(@ViewBuilder _ block: (Self) -> V) -> V { return block(self) }
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
