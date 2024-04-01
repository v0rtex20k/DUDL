//
//  JoinView.swift
//  DUDL
//
//  Created by V on 1/30/24.
//

import Foundation
import SwiftUI
import Combine

func isValidGameCode(_ code: String) -> Bool {
    guard !code.isEmpty else {
        return false
    }
    
    guard code.lowercased() == code else {
        return false
    }
    
    let regex  = "^[a-z]{2,50}+(?:-[a-z]{2,50}+)+$"
    let test = NSPredicate(format: "SELF MATCHES %@", regex)
    
    return test.evaluate(with: code)
}


struct JoinView : View {
    @State private var alertMessage: String = ""
    @State private var shouldShowAlert: Bool = false
    @State private var shouldShowContent: Bool = true
    let alertTitle = "Unable to Join Game"
    
    private let maxLen = 50 // just to prevent some type of crazy long string
    
    @Binding var gameCode: String
    @Binding var currentView: ViewFinder
    @Binding var restController: RestController
    
    @FocusState private var keyboardFocused: Bool
    
    func limitText() {
        gameCode = gameCode.replacingOccurrences(of:"[^a-z-]", with: "", options: .regularExpression)
        if gameCode.count > maxLen {
            gameCode = String(gameCode.prefix(maxLen))
        }
    }
    
    func joinWrapper(_ code: String) {
        if isValidGameCode(code) {
            print("Attempting to join Game \"\(code)\"...")
            shouldShowContent = false
            Task.detached {
                await joinGame()
            }
        } else {
            print("Ignoring invalid game code \(code)")
        }
    }
    
    func joinGame() async {
        await restController.joinExistingGame(gameCode) { result in
            switch result {
            case .success(let jgr):
                currentView = jgr.existingPlayer ? .lobby : .profile
                shouldShowContent = false
                print("Joined Game \(jgr.playerId)")
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
    
    func clearGameCode () {
        gameCode.removeAll()
    }
    
    
    var body: some View {
        GeometryReader { geo in
            BlackDraggableZStack(currentView: $currentView, dragToView: .home, onDragEndFunc: clearGameCode) {
                VStack {
                    Spacer()
                    RestfulGroup(currentView: $currentView, gameCode: $gameCode, shouldShowAlert: $shouldShowAlert, alertTitle: alertTitle, alertMessage: alertMessage, shouldShowContent: $shouldShowContent, contentValue: $gameCode) {code in
                        VStack {
                            Text("Game Code")
                                .padding()
                                .foregroundStyle(Color(primary_color))
                                .font(Font.custom("Galvji", size: 16))
                            TextField("game-code", text: code)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                                .onReceive(Just(code)) { _ in
                                    limitText()
                                }
                                .focused($keyboardFocused)
                                .onAppear {
                                    if (code.wrappedValue.count > 1) {
                                            keyboardFocused = true
                                    }
                                }
                                .onSubmit{ joinWrapper(code.wrappedValue) }
                                .foregroundStyle(.black)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .multilineTextAlignment(.center)
                                .frame(width: geo.size.width * 0.85)
                                .font(Font.custom("Galvji", size: 20))
                        }
                    }
                    Spacer()
                    Spacer()
                    Spacer()
                }
            }
        }
    }
}

//
//#Preview {
//   struct PreviewWrapper: View {
//       @State var rc: RestController = RestController(host: "192.168.1.7", port:8001)
//       var body: some View {
//           JoinView(gameCode: .constant("happy-hippo"), currentView: .constant("JoinView"), restController: $rc)
//       }
//   }
//   return PreviewWrapper()
//}
