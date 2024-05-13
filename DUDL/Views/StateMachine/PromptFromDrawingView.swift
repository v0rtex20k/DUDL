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
    @Binding var prompt: String
    @Binding var drawing: String
    @Binding var secondsRemaining: TimeInterval
    
    @State var canvasView = PKCanvasView()
    
    private let maxLen = 50 // just to prevent some type of crazy long string
    
    func limitText() {
        print("LIMITING TEXT: \(prompt.count) vs \(maxLen)")
        prompt = prompt.replacingOccurrences(of: "[^\\S ]+", with: "", options: .regularExpression)
        if prompt.count > maxLen {
            prompt = String(prompt.prefix(maxLen))
        }
    }
    
    var body: some View {
        NavigationStack {
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
                        //                if canvasView.drawing.bounds.isEmpty {
                        //                    ZStack {
                        //                        ProgressView {
                        //                            Text("Downloading Content")
                        //                                .foregroundStyle(Color(primary_color))
                        //                                .font(Font.custom("Galvji", size: 20))
                        //                                .foregroundStyle(Color(primary_color))
                        //                        }
                        //                        .padding()
                        //                        .progressViewStyle(.circular)
                        //                        .tint(Color(primary_color))
                        //                        .zIndex(2)
                        //                    }
                        //                } else {
                        Poster(canvasView: $canvasView)
                            .border(Color(primary_color), width:3)
                        //                }
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    VStack {
                        Text("\(Int(ceil(secondsRemaining)))")
                            .font(.subheadline)
                            .foregroundStyle(Color(primary_color))
                    }
                }
            }
            .toolbarBackground(.hidden, for: .automatic)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
}

#Preview {
    PromptFromDrawingView(prompt: .constant("fake-prompt"), drawing: .constant("d3Jk8AEACAASEAAAAAAAAAAAAAAAAAAAAAASEB480hIPJE7Bhb4JrnVh0Z0aBggAEAAYABoGCAEQARgBIisKFA0AAIA/FQAAgD8dAACAPyUAAIA/EhFjb20uYXBwbGUuaW5rLnBlbhgDKp0CChBWX73c27tCr5ymstO134fREgYIABABGAEaBggAEAEYACAAKtkBChAx4kradRhE9bgj9XBZSIy9ETwWbbXS+MVBGAogByj4BzIQ6AMAAAAAue4AAP9/AACAPzqgAauqZ0NVVZtDAAAAAJ3jXkBbjGVDfWybQwP8jz4PCnlAAABkQ6uqmEM6i5g+jLuRQJgnW0Pkbo1DeVOlPtjCrUCrqkxDAAB1Q8GMqT6N97xA1t8/Q3HZTEMu3b0+WAnBQAAAN0OrqipDAUjCPjCfsEDfkjBDkNcOQ5PE0z726YxAIW0uQ8V9A0PwF9Q+bx+MQAAALkOrqgFDhPX1Pp3jXkBAATIUDQAALEMVAAD+Qh0AAHhCJQAAOkNA4PThktUHOgYIABAAGABCEAcbiIq7C0UZt2zDonXg4oE="), secondsRemaining: .constant(30))
}
