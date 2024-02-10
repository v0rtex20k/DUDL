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

struct StartView : View {
    @State private var shouldShowContent: Bool = false
    @State private var shouldShowAlert: Bool = false
    @State private var alertMessage: String = ""
    let alertTitle: String = "Unable to Start Game"
    
    @Binding var gameCode: String
    @Binding var currentView: ViewFinder
    @Binding var restController: RestController
    
    func startGame() async {
        await restController.startNewGame { result in
            switch result {
                case .success(let g):
                    gameCode = g.gameCode
                    shouldShowContent = true
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
        BlackDraggableZStack(currentView: $currentView, dragToView: .home, onDragEndFunc: nil) {
            RestfulGroup(currentView: $currentView, gameCode: $gameCode, shouldShowAlert: $shouldShowAlert, alertTitle: alertTitle, alertMessage: alertMessage, shouldShowContent: $shouldShowContent) { code in
                    VStack{
                        ShareLink(item: "Let's DÜDL: \(gameCode)") {
                            Text(code.wrappedValue)
                                .font(Font.custom("Galvji", size: 25))
                                .foregroundColor(Color(primary_color))
                                .shadow(color: Color(primary_color), radius: 10)
                                .shadow(color: Color(primary_color), radius: 20)
                        }
                        Text("Tap the code to share")
                            .padding()
                            .foregroundColor(Color(primary_color))
                            .font(Font.custom("Galvji", size: 8))
                    }
            }.task {
                await startGame()
            }
        }
    }
}

//#Preview {
//   struct PreviewWrapper: View {
//       @State var rc: RestController = RestController(host: "192.168.1.7", port:8001)
//       var body: some View {
//           StartView(gameCode: .constant("happy-lizard"), currentView: .constant("HomeView"), restController: $rc)
//       }
//   }
//   return PreviewWrapper()
//}
