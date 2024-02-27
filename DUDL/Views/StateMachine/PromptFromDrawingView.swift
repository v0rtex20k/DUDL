//
//  PromptFromDrawingView.swift
//  DUDL
//
//  Created by V on 2/18/24.
//

import SwiftUI

struct PromptFromDrawingView: View {
    @Binding var drawing: String
    @Binding var prompt: String
    
    var body: some View {
        Text("Prompt From Drawing!").foregroundColor(Color(primary_color))
    }
}

#Preview {
    PromptFromDrawingView(drawing: .constant("base64-encoded-drawing"), prompt: .constant("fake-prompt"))
}
