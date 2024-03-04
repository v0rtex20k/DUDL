//
//  DudlCanvas.swift
//  DUDL
//
//  Created by V on 3/4/24.
//
import SwiftUI
import PencilKit
import ObjectiveC

class Coordinator: NSObject, PKCanvasViewDelegate {
    @Binding var canvasView: PKCanvasView
    @Binding var toolPicker: PKToolPicker
    let onChange: () -> Void
    
    init(canvasView: Binding<PKCanvasView>, toolPicker: Binding<PKToolPicker>, onChange: @escaping () -> Void) {
        self._canvasView = canvasView
        self._toolPicker = toolPicker
        self.onChange = onChange
    }
    
    deinit {
        toolPicker.setVisible(false, forFirstResponder: canvasView)
        toolPicker.removeObserver(canvasView)
    }
    
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        if !canvasView.drawing.bounds.isEmpty {
            onChange()
        }
    }
}

struct DudlCanvas: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var toolPicker: PKToolPicker
    
    @Binding var showTools: Bool
    
    let onChange: () -> Void
    
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.minimumZoomScale = 0.2
        canvasView.maximumZoomScale = 4.0
        canvasView.backgroundColor = UIColor(Color.black)
        canvasView.becomeFirstResponder()

        toolPicker.setVisible(showTools, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        toolPicker.selectedTool = PKInkingTool(.pen, color: primary_color, width: 10)
        
        //assign coordinator as delegate
        canvasView.delegate = context.coordinator
        
        
        return canvasView
    }
    

    func updateUIView(_ canvasView: PKCanvasView, context: Context){
        toolPicker.setVisible(showTools, forFirstResponder: canvasView)
    }
    
    func showToolPicker() {
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(canvasView: $canvasView, toolPicker: $toolPicker, onChange: onChange)
    }
    
    func isBlank() -> Bool {
        return self.canvasView.drawing.strokes.isEmpty
    }
    
}
