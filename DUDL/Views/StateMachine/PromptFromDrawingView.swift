//
//  PromptFromDrawingView.swift
//  DUDL
//
//  Created by V on 2/18/24.
//

import SwiftUI
import Combine
import PencilKit

struct AvailableNavigationStack<Content>: View where Content: View {
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        if #available(iOS 16, *) {
            NavigationStack(root: content)
        } else {
            ZStack(content: content)
        }
    }
}

struct AvailableTextField: View {
    var defaultText: String
    var bodyText: Binding<String>
    
    var body: some View {
        if #available(iOS 16, *) {
            TextField(defaultText, text: bodyText, axis: .vertical)
        } else {
            TextField(defaultText, text: bodyText)
        }
    }
    
}



struct PromptFromDrawingView: View {
    private let maxLen = 50 // just to prevent some type of crazy long string

    @ObservedObject var stateMachine : StateMachine
        
    @State var canvasView = PKCanvasView()
    
    func limitText() {
        print("LIMITING TEXT: \(stateMachine.dataToUpload.count) vs \(maxLen)")
        stateMachine.dataToUpload = stateMachine.dataToUpload.replacingOccurrences(of: "[^\\S ]+", with: "", options: .regularExpression)
        if stateMachine.dataToUpload.count > maxLen {
            stateMachine.dataToUpload = String(stateMachine.dataToUpload.prefix(maxLen))
        }
    }
    
    var body: some View {
        AvailableNavigationStack {
            GeometryReader { geo in
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    VStack {
                        Spacer()
                        Text("Describe this image")
                            .padding()
                            .foregroundStyle(Color(primary_color))
                            .font(Font.custom("Galvji", size: 18))
                            AvailableTextField(defaultText: "image-description", bodyText: $stateMachine.dataToUpload)
                            .lineLimit(5)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .apply {
                                if #available(iOS 17.0, *) {
                                    $0.onChange(of: stateMachine.dataToUpload) {
                                        limitText()
                                    }
                                } else {
                                    $0.onChange(of: stateMachine.dataToUpload) { _ in
                                        limitText()
                                    }
                                }
                            }
                            .foregroundStyle(.black)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .multilineTextAlignment(.center)
                            .frame(width: 0.8 * geo.size.width)
                            .fixedSize(horizontal: false, vertical: true)
                            .font(Font.custom("Galvji", size: 24))
                        Text("\(stateMachine.dataToUpload.count) / \(maxLen)")
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
                }
                .apply {
                    if #available(iOS 17.0, *) {
                        $0.onChange(of: stateMachine.downloadedData) {
                            do {
                                canvasView.drawing = try PKDrawing(base64Encoded: stateMachine.downloadedData)
                            } catch {
                                canvasView.drawing = PKDrawing()
                                print("[PFD] Failed to render drawing: \(error)")
                            }
                        }
                    } else {
                        $0.onChange(of: stateMachine.downloadedData) { ddata in
                            do {
                                canvasView.drawing = try PKDrawing(base64Encoded: ddata)
                            } catch {
                                canvasView.drawing = PKDrawing()
                                print("[PFD] Failed to render drawing: \(error)")
                            }
                        }
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
            .apply {
                if #available(iOS 16.0, *) {
                    $0.toolbarBackground(.hidden, for: .automatic)
                } else {
                    // ignore
                }
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
}

#Preview {
    PromptFromDrawingView(stateMachine: StateMachine())
}
