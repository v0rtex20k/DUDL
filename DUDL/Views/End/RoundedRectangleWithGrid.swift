//
//  GriddedRectangle.swift
//  DUDL
//
//  Created by V on 11/4/24.
//

import SwiftUI
import Foundation

struct RoundedRectangleWithGrid: View {
    var gridColor: Color = Color.gray.opacity(0.5) // Set your desired grid color here
    var gridSpacing: CGFloat = 20 // Set your desired grid spacing here
    var cornerRadius: CGFloat = 20 // Set your desired corner radius here
    
    var body: some View {
        ZStack {
            let shadeOfGray = 180.0 / 255.0
            // Base layer: RoundedRectangle
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(red: shadeOfGray, green: shadeOfGray, blue: shadeOfGray))
                .stroke(.white, lineWidth: 4)
            
            // Overlay: Grid
            GridPattern(gridColor: gridColor, gridSpacing: gridSpacing)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius)) // Clip to match RoundedRectangle's shape
        }
    }
}

struct GridPattern: View {
    var gridColor: Color
    var gridSpacing: CGFloat

    var body: some View {
        Canvas { context, size in
            var path = Path()

            // Draw vertical grid lines
            for x in stride(from: 0, through: size.width, by: gridSpacing) {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }

            // Draw horizontal grid lines
            for y in stride(from: 0, through: size.height, by: gridSpacing) {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }

            context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
        }
    }
}
