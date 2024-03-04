//
//  DrawFromPromptView.swift
//  DUDL
//
//  Created by V on 2/18/24.
//

import SwiftUI
import UIKit
import PencilKit

struct DrawFromPromptView: View {
    @Binding var prompt: String
    @Binding var drawing: String

    
    @Environment(\.undoManager) private var undoManager
    
    @State private var canvasView = PKCanvasView()
    
    @State var showTools: Bool = true
    @State private var toolPicker = PKToolPicker.init()
    
    private func canvasDidChange() {
        if showTools {
            // if it was manually updated, hide it again
            showTools = false
        }
    }
    
    private var canvasToolbar: some View  {
        HStack {
            Spacer()
            Button("Clear", systemImage: "xmark.circle.fill", role: .destructive) {
                canvasView.drawing = PKDrawing()
                showTools = true
            }
            Spacer()
            Button("Undo", systemImage: "arrow.uturn.backward.circle.fill", role: ButtonRole.cancel) {
                undoManager?.undo()
                if canvasView.drawing.bounds.isEmpty {
                    showTools = true
                }
            }
            Spacer()
            Button("Redo", systemImage: "arrow.uturn.forward.circle.fill") {
                undoManager?.redo()
            }.foregroundStyle(Color.green)
            Spacer()
        }
    }
    
    var body: some View {
        VStack {
            VStack{
                Text("Draw ...")
                    .font(Font.custom("Galvji", size: 14))
                    .foregroundStyle(Color(primary_color))
                Text("\"" + prompt + "\"")
                        .padding()
                    .font(Font.custom("Galvji-Oblique", size: 20))
                    .foregroundStyle(Color(primary_color))
                    .multilineTextAlignment(.center)
                
            }
            .padding()
            canvasToolbar.padding()
            GeometryReader { geo in
                DudlCanvas(canvasView: $canvasView, toolPicker: $toolPicker, showTools: $showTools, onChange: canvasDidChange)
//                    .frame(height: geo.size.height * 0.8)
                    .border(Color(primary_color), width: 3)
                    .padding()
            }
            Button("", systemImage: "pencil.circle.fill") {
                // clicking this button shows tools and hides itself
                showTools = true
                
            }
            .disabled(showTools)
            .opacity(showTools ? 0 : 1)
            .foregroundStyle(Color(primary_color))
            .font(Font.custom("Galvji-Bold", size: 25))
        }.background(Color.black)
    }
}

#Preview {
    DrawFromPromptView(prompt: .constant("Something really funny that is super hilarious right now"), drawing: .constant(""))
}
