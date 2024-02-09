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
            .aspectRatio(contentMode: .fill)
            .shadow(radius: 5.0)

    }
}
