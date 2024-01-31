//
//  ColorPicker.swift
//  DUDL
//
//  Created by V on 1/30/24.
//

import Foundation
import SwiftUI

struct ColorPickerView: View {
    @State private var bgColor =
        Color(.sRGB, red: 0.98, green: 0.9, blue: 0.2)
    var body: some View {
        VStack {
            ColorPicker("Alignment Guides", selection: $bgColor)
        }
    }
}
