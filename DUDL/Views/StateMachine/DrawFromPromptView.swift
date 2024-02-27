//
//  DrawFromPromptView.swift
//  DUDL
//
//  Created by V on 2/18/24.
//

import SwiftUI

struct DrawFromPromptView: View {
    @Binding var prompt: String
    @Binding var drawing: String
    
    
    var body: some View {
        Text("Draw From Prompt: \(prompt)").foregroundColor(Color(primary_color))
    }
}

#Preview {
    DrawFromPromptView(prompt: .constant("default-prompt"), drawing: .constant("base64-encoded-drawing"))
}
