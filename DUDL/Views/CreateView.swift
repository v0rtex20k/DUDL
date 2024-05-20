//
//  CreateView.swift
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

struct AvailableShareLink : View {
    var gameCode: String
    var code: Binding<String>

    var body: some View {
        
        let t = Text(code.wrappedValue)
                .font(Font.custom("Galvji", size: 24))
                .foregroundColor(Color(primary_color))
                .shadow(color: Color(primary_color), radius: 20)
                .shadow(color: Color(primary_color), radius: 30)
        
        if #available(iOS 16, *) {
            ShareLink(item: "Let's DÜDL: \(gameCode)") { t }
        } else {
            t
        }
    }
}

struct CreateView : View {
    @State private var shouldShowContent: Bool = false
    @State private var shouldShowAlert: Bool = false
    @State private var alertMessage: String = ""
    let alertTitle: String = "Unable to Create Game"
    
    @Binding var gameCode: String
    @Binding var currentView: ViewFinder
    @Binding var restController: RestController
    
    func createGame() async {
        await restController.createGame { result in
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
            RestfulGroup(currentView: $currentView, gameCode: $gameCode, shouldShowAlert: $shouldShowAlert, alertTitle: alertTitle, alertMessage: alertMessage, shouldShowContent: $shouldShowContent, contentValue: $gameCode) { code in
                    VStack{
                        AvailableShareLink(gameCode: gameCode, code: code)
                        Text("Tap the code to share")
                            .padding()
                            .foregroundColor(Color(primary_color))
                            .font(Font.custom("Galvji", size: 8))
                    }
            }.task {
                await createGame()
            }
        }
    }
}

//#Preview {
//   struct PreviewWrapper: View {
//       @State var rc: RestController = RestController(host: "192.168.1.7", port:8001)
//       var body: some View {
//           CreateView(gameCode: .constant("happy-lizard"), currentView: .constant("HomeView"), restController: $rc)
//       }
//   }
//   return PreviewWrapper()
//}
