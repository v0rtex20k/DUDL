//
//  SwiftUIView.swift
//  DUDL
//
//  Created by V on 2/10/24.
//

import SwiftUI
import Combine

struct OLDInitialPromptView: View {
    @Binding var textPrompt: String
    @Binding var startDate: Date
    
    @Binding var timeLeft: Int
    
    @State var size: CGSize
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
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
                .onAppear {
                    // just in case
                    startDate = Date.now
                }
                .onDisappear {
                    timer.upstream.connect().cancel()
                }
                .onReceive(Just(textPrompt)) { _ in
                    limitText()
                }
                .onReceive(timer) { firedDate in
                    timeLeft = Int(firedDate.timeIntervalSince(startDate)) // seconds
                    if timeLeft == 0 {
                        // send prompt to server, go to next view
                    }
                }
                .foregroundStyle(.black)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .multilineTextAlignment(.center)
                .frame(width: size.width * 0.85)
                .font(Font.custom("Galvji", size: 20))
        }
    }
    
}
