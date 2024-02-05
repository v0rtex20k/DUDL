//
//  StartView.swift
//  DUDL
//
//  Created by Victor on 1/28/24.
//

// When starting a game, all you need is a game code

import Foundation
import SwiftUI

struct TextWrapper: Identifiable {
    let id = UUID()
    let text: String
}

struct ActivityViewController: UIViewControllerRepresentable {
    let textWrapper: TextWrapper
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [textWrapper.text], applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}

struct StartView : View {
    @State private var shouldShowAlert: Bool = false
    @State private var alertMessage: String = ""
    
    @Binding var gameCode: String
    @Binding var currentView: String
    @Binding var restController: RestController
    
    func startGame() async {
        await restController.startNewGame { result in
            switch result {
                case .success(let g):
                gameCode = g.gameCode
                print("Started a new game \(gameCode)")
                case .failure(let error):
                    switch error {
                        case .serviceUnavailable:
                            alertMessage = "Failed to connect to server \n Please check your internet connection"
                        default:
                            alertMessage = "Something went wrong \n Please try again later"
                    }
                    shouldShowAlert = true
                    print(error.localizedDescription)
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            Group {
                if shouldShowAlert {
                    Text("")
                        .alert("Unable to Start Game", isPresented: $shouldShowAlert) {
                            Button("OK", role: .cancel) {
                                gameCode.removeAll()
                                currentView = "HomeView"
                            }
                        } message: {
                            Text(alertMessage)
                        }
                } else if !gameCode.isEmpty {
                    VStack{
                        ShareLink(item: "Let's DÜDL: \(gameCode)") {
                            Text(gameCode)
                                .foregroundStyle(.white)
                                .font(Font.custom("Galvji", size: 25))
                        }
                        Text("Tap the code to share")
                            .padding()
                            .foregroundStyle(.white)
                            .font(Font.custom("Galvji", size: 8))
                    }

                }   else {
                        ProgressView {
                            Text("Connecting to Server")
                                .foregroundStyle(.white)
                                .padding()
                                .font(Font.custom("Galvji", size: 20))
                                .foregroundStyle(.white)
                        }
                        .progressViewStyle(.circular)
                        .tint(.white)
                    
                }
            }
        }
        .onAppear {
            currentView = "StartView"
        }
        .onTapGesture(count: 2) {
            UIPasteboard.general.string = gameCode
            currentView = "HomeView"
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
        }

        .task {
            await startGame()
        }
    }
}

#Preview {
   struct PreviewWrapper: View {
       @State var rc: RestController = RestController(host: "192.168.1.7", port:8001)
       var body: some View {
           StartView(gameCode: .constant("happy-lizard"), currentView: .constant("HomeView"), restController: $rc)
       }
   }
   return PreviewWrapper()
}
