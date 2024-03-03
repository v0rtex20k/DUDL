//
//  PromptFromDrawingView.swift
//  DUDL
//
//  Created by V on 2/18/24.
//

import SwiftUI
import Combine

struct PromptFromDrawingView: View {
    @Binding var drawing: String
    @Binding var prompt: String
    
    private let maxLen = 100 // just to prevent some type of crazy long string
    
    func limitText() {
        prompt = prompt.replacingOccurrences(of:"[^a-z-\\s]", with: "", options: .regularExpression)
        if prompt.count > maxLen {
            prompt = String(prompt.prefix(maxLen))
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            GeometryReader { geo in
                
                Spacer()
                Text("Describe this drawing")
                    .padding()
                    .foregroundStyle(Color(primary_color))
                    .font(Font.custom("Galvji", size: 16))
                TextField("drawing-description", text: $prompt)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .onReceive(Just(prompt)) { _ in
                        limitText()
                    }
                    .foregroundStyle(.black)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .multilineTextAlignment(.center)
                    .frame(width: 0.75 * geo.size.width)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(Font.custom("Galvji", size: 20))
            }
            Spacer()
        }
    }
}

#Preview {
    PromptFromDrawingView(drawing: .constant("base64-encoded-drawing"), prompt: .constant("fake-prompt"))
}
