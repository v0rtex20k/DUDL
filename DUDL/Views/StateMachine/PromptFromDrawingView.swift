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
                Poster(canvasView: $canvasView)
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
                Spacer()
                Spacer()
                
                }
            }.onAppear {
                do {
                    canvasView.drawing = try PKDrawing(base64Encoded: drawing)
                } catch {
                    // MARK: FIXME!!!
                    print("BAD")
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
    PromptFromDrawingView(drawing: "base64-encoded-drawing", prompt: .constant("fake-prompt"))
}
