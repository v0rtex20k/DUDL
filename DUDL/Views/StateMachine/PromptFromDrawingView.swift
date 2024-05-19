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
    private let maxLen = 50 // just to prevent some type of crazy long string

    @StateObject var stateMachine : StateMachine = StateMachine()
        
    @State var canvasView = PKCanvasView()
    
    func limitText() {
        print("LIMITING TEXT: \(stateMachine.dataToUpload.count) vs \(maxLen)")
        stateMachine.dataToUpload = stateMachine.dataToUpload.replacingOccurrences(of: "[^\\S ]+", with: "", options: .regularExpression)
        if stateMachine.dataToUpload.count > maxLen {
            stateMachine.dataToUpload = String(stateMachine.dataToUpload.prefix(maxLen))
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
                        TextField("image-description", text: $stateMachine.dataToUpload, axis: .vertical)
                            .lineLimit(5)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .onReceive(Just(stateMachine.dataToUpload)) { _ in
                                limitText()
                            }
                            .foregroundStyle(.black)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .multilineTextAlignment(.center)
                            .frame(width: 0.8 * geo.size.width)
                            .fixedSize(horizontal: false, vertical: true)
                            .font(Font.custom("Galvji", size: 24))
                        Text("\($stateMachine.dataToUpload.wrappedValue.count) / \(maxLen)")
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
                        canvasView.drawing = try PKDrawing(base64Encoded: stateMachine.downloadedData)
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
                        Text("\(Int(ceil(stateMachine.secondsRemaining)))")
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
    PromptFromDrawingView(stateMachine: StateMachine())
}
