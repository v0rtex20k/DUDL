//
//  InitialPromptState.swift
//  DUDL
//
//  Created by V on 2/18/24.
//

import SwiftUI
import Combine

struct InitialPromptView: View {
    @Binding var textPrompt: String
    private let maxLen = 100 // just to prevent some type of crazy long string
    
    func limitText() {
        textPrompt = textPrompt.replacingOccurrences(of:"[^a-z-\\s]", with: "", options: .regularExpression)
        if textPrompt.count > maxLen {
            textPrompt = String(textPrompt.prefix(maxLen))
        }
    }
    
    var body: some View {
        VStack {
            Text("Say something funny")
                .padding()
                .foregroundStyle(Color(primary_color))
                .font(Font.custom("Galvji", size: 16))
            TextField("something-funny", text: $textPrompt)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .onReceive(Just(textPrompt)) { _ in
                    limitText()
                }
                .foregroundStyle(.yellow)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .multilineTextAlignment(.center)
                .font(Font.custom("Galvji", size: 20))
        }
    }
    
}

