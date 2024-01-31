//
//  JoinView.swift
//  DUDL
//
//  Created by V on 1/30/24.
//

import Foundation
import SwiftUI

func isValidGameCode(_ s: String) -> Bool {
    return true
}

struct JoinView : View {
    @State private var gameCode: String = ""
    @State private var alertMessage: String = ""
    @State private var wasSubmitted: Bool = false
    @State private var shouldShowAlert: Bool = false
    
    @Binding var currentView: String
    @Binding var restController: RestController
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                VStack {
                    Spacer()
                    Group {
                        if !wasSubmitted {
                            Text("Game Code")
                                .padding()
                                .foregroundStyle(.white)
                                .font(Font.custom("Galvji", size: 16))
                            TextField("game-code", text: $gameCode)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                                .onSubmit {
                                    if isValidGameCode(gameCode) {
                                        print("Attempting to join Game  \"\(gameCode)\"...")
                                        Task {
                                            await restController.joinExistingGame(gameCode) { result in
                                                wasSubmitted = true
                                                switch result {
                                                case .success(let jgr):
                                                    currentView = "PlayerProfileView"
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

                                    } else {
                                        print("Ignoring invalid game code \(gameCode)")
                                    }
                            }
                            .foregroundStyle(.black)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .multilineTextAlignment(.center)
                            .frame(width: geo.size.width * 0.80)
                            .font(Font.custom("Galvji", size: 20))
                            Spacer()
                        } else if shouldShowAlert {
                            Text("")
                                .alert("Unable to Join Game", isPresented: $shouldShowAlert) {
                                    Button("OK", role: .cancel) {
                                        gameCode = ""
                                        currentView = "HomeView"
                                    }
                                } message: {
                                    Text(alertMessage)
                                }
                        } else {
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
            }
        }
        .onTapGesture(count: 1) {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
        }
        .onTapGesture(count: 2) {
            UIPasteboard.general.string = gameCode
            currentView = "PlayerRegistrationView"
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
        }
    }
}

#Preview {
   struct PreviewWrapper: View {
       @State var rc: RestController = RestController(host: "127.0.0.1", port:8001)
       var body: some View {
           LobbyView(currentView: .constant("LobbyView"), restController: $rc)
       }
   }
   return PreviewWrapper()
}
