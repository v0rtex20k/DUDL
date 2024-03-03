//
//  DrawFromPromptView.swift
//  DUDL
//
//  Created by V on 2/18/24.
//

import SwiftUI
import UIKit
import PencilKit


struct MyCanvas: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var toolPicker: PKToolPicker
    
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.minimumZoomScale = 0.2
        canvasView.maximumZoomScale = 4.0
        canvasView.backgroundColor = UIColor(Color.black)
        canvasView.becomeFirstResponder()
        
        canvasView.tool = PKInkingTool(.marker, color: primary_color, width: 10)
        

        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        
        
        return canvasView
    }
    

    func updateUIView(_ uiView: PKCanvasView, context: Context){
        // pass
    }
    
}

struct DrawFromPromptView: View {
    @Binding var prompt: String
    @Binding var drawing: String
    
    @Environment(\.undoManager) private var undoManager
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker.init()
    
    
    private var canvasToolbar: some View  {
        HStack {
            Spacer()
            Button("Clear", systemImage: "xmark.circle.fill", role: .destructive) {
                canvasView.drawing = PKDrawing()
            }
            Spacer()
            Button("Undo", systemImage: "arrow.uturn.backward.circle.fill", role: ButtonRole.cancel) {
                undoManager?.undo()
            }
            Spacer()
            Button("Redo", systemImage: "arrow.uturn.forward.circle.fill") {
                undoManager?.redo()
            }
            Spacer()
        }
    }
    
    var body: some View {
        VStack {
            VStack{
                Text("Draw ...")
                        .padding()
                    .font(Font.custom("Galvji", size: 14))
                    .foregroundStyle(Color(primary_color))
                Text(prompt)
                        .padding()
                    .font(Font.custom("Galvji", size: 20))
                    .foregroundStyle(Color(primary_color))
                    .multilineTextAlignment(.center)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .foregroundStyle(Color(primary_color))
                    )
                
            }
            .padding()
            canvasToolbar.padding()
            MyCanvas(canvasView: $canvasView, toolPicker: $toolPicker)
                .padding()
        }.background(Color.black)
    }
}

#Preview {
    DrawFromPromptView(prompt: .constant("Something Funny that is super hilarious omg"), drawing: .constant(""))
}
