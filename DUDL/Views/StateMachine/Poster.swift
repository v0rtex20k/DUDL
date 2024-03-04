//
//  Poster.swift
//  DUDL
//
//  Created by V on 3/4/24.
//

import Foundation
import SwiftUI
import PencilKit

struct Poster: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.minimumZoomScale = 0.5
        canvasView.maximumZoomScale = 3.0
        canvasView.backgroundColor = UIColor(Color.black)
        
        canvasView.drawingGestureRecognizer.isEnabled = false
        
        return canvasView
    }
    

    func updateUIView(_ canvasView: PKCanvasView, context: Context){}
}
