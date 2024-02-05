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
    
    let regex  = "^[a-z]{3,50}+(?:-[a-z]{3,50}+)+$"
    let test = NSPredicate(format: "SELF MATCHES %@", regex)
    
    return test.evaluate(with: code)
}


struct JoinView : View {
    @State private var gameCode: String = ""
    @State private var alertMessage: String = ""
    @State private var wasSubmitted: Bool = false
    @State private var shouldShowAlert: Bool = false
    
    private let maxLen = 100 // just to prevent some type of crazy long string
    
    @Binding var currentView: String
    @Binding var restController: RestController
    
    func limitText() {
        if gameCode.count > maxLen {
            gameCode = String(gameCode.prefix(maxLen))
        }
    }
    
    func joinGame() async {
        await restController.joinExistingGame(gameCode) { result in
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
                                .onReceive(Just(gameCode)) { _ in
                                    limitText()
                                }
                                .onSubmit {
                                    if isValidGameCode(gameCode) {
                                        print("Attempting to join Game  \"\(gameCode)\"...")
                                        wasSubmitted = true
                                        Task.detached {
                                            await joinGame()
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
                Spacer()
                Spacer()
                Spacer()
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                currentView = "HomeView"
                let impact = UIImpactFeedbackGenerator(style: .heavy)
                impact.impactOccurred()
            }
            .onTapGesture(count: 1) {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
            }
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            currentView = "JoinView"
        }
    }
}

#Preview {
   struct PreviewWrapper: View {
       @State var rc: RestController = RestController(host: "192.168.1.7", port:8001)
       var body: some View {
           JoinView(currentView: .constant("JoinView"), restController: $rc)
       }
   }
   return PreviewWrapper()
}
