//
//  CustomProgressView.swift
//  DUDL
//
//  Created by V on 1/29/24.
//

import Foundation
import SwiftUI

struct CustomProgressView: ProgressViewStyle {
    var strokeColor = Color.white
    var strokeWidth = 15.0

    func makeBody(configuration: Configuration) -> some View {
         let fractionCompleted = configuration.fractionCompleted ?? 0

        return ZStack {
            Circle()
                .trim(from: 0, to: fractionCompleted)
                .stroke(strokeColor, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}
