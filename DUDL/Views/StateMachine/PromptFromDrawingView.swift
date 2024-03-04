//
//  PromptFromDrawingView.swift
//  DUDL
//
//  Created by V on 2/18/24.
//

import SwiftUI
import Combine
import PencilKit

struct PromptFromDrawingView: View {
    let drawing: String
    @Binding var prompt: String
    private let maxLen = 50 // just to prevent some type of crazy long string

    @State var canvasView = PKCanvasView()
    
    func limitText() {
        print("LIMITING TEXT: \(prompt.count) vs \(maxLen)")
        prompt = prompt.replacingOccurrences(of: "[^\\S ]+", with: "", options: .regularExpression)
        if prompt.count > maxLen {
            prompt = String(prompt.prefix(maxLen))
        }
    }
    
    var body: some View {
        GeometryReader { geo in
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                Text("Describe this image")
                        .padding()
                        .foregroundStyle(Color(primary_color))
                        .font(Font.custom("Galvji", size: 18))
                TextField("image-description", text: $prompt, axis: .vertical)
                        .lineLimit(5)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .onReceive(Just(prompt)) { _ in
                            limitText()
                        }
                        .foregroundStyle(.black)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .multilineTextAlignment(.center)
                        .frame(width: 0.8 * geo.size.width)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(Font.custom("Galvji", size: 24))
                Text("\($prompt.wrappedValue.count) / \(maxLen)")
                        .padding()
                        .foregroundStyle(Color(primary_color))
                        .font(Font.custom("Galvji", size: 16))
                if canvasView.drawing.bounds.isEmpty {
                    ProgressView {
                        Text("Downloading Content")
                            .foregroundStyle(Color(primary_color))
                            .font(Font.custom("Galvji", size: 20))
                            .foregroundStyle(Color(primary_color))
                    }
                    .padding()
                    .progressViewStyle(.circular)
                    .tint(Color(primary_color))
                } else {
                    Poster(canvasView: $canvasView)
                        .border(Color(primary_color), width:3)
                }
                Spacer()
                
                }
            }.onAppear {
                do {
                    canvasView.drawing = try PKDrawing(base64Encoded: drawing)
                } catch {
                    canvasView.drawing = PKDrawing()
                    print("Error info: \(error)")
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

#Preview {
    PromptFromDrawingView(drawing: "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", prompt: .constant("fake-prompt"))
}
