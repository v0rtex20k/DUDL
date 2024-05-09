//
//  PlayerProfileView.swift
//  DUDL
//
//  Created by V on 1/30/24.
//

import Foundation
import Combine
import SwiftUI


struct ProfileView : View {
    @Binding var gameCode: String
    @Binding var currentView: ViewFinder
    @Binding var restController: RestController
    
    private let maxLen = 15
    private let alertTitle = "Unable to create Player Profile"
    
    @State var nickname: String = ""
    @State private var playerColor = Color.random(from: [.red, .yellow, .green, .blue, .purple, .orange])
    @State private var alertMessage: String = ""
    @State private var wasSubmitted: Bool = false
    @State private var shouldShowAlert: Bool = false
    @State private var shouldShowContent: Bool = true
    
    @Environment(\.self) var env
    
    func limitText(_ upper: Int) {
        if nickname.count > upper {
            nickname = String(nickname.prefix(upper))
        }
    }
    
    func updateProfile() async {
        let c = playerColor.resolve(in: env)
        shouldShowContent = false
        print("Attempting to Update Player Profile \"\(nickname)\" in \(gameCode) : \(c.description) ...")
        await restController.updatePlayerProfile(code: gameCode, nickname: nickname, rgba: RGBA(r: c.red, g: c.green, b: c.blue, a: c.opacity)) { result in
            wasSubmitted = true
            switch result {
            case .success(let uppr):
                currentView = .lobby
                print("Updated \(uppr.playerId)'s Profile")
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
    
    func leaveGame() async {
        await restController.removePlayer(code: gameCode) { result in
            switch result {
            case .success:
                currentView = .home
                print("Successfully left \(gameCode)")
            case .failure(let error):
                switch error {
                case .serviceUnavailable:
                    alertMessage = "Failed to connect to server \n Please check your internet connection"
                default:
                    alertMessage = "Something went wrong \n Please try again later"
                }
                print(error.localizedDescription)
            }
        }
        
        gameCode.removeAll()
    }
    
    
    var body: some View {
        GeometryReader { geo in
            let minDim = min(geo.size.width, geo.size.height)
            BlackDraggableZStack(currentView: $currentView, dragToView: .home, onDragEndFunc: leaveGame) {
                VStack {
                    RestfulGroup(currentView: $currentView, gameCode: $gameCode, shouldShowAlert: $shouldShowAlert, alertTitle: alertTitle, alertMessage: alertMessage, shouldShowContent: $shouldShowContent, contentValue: $gameCode) { code in
                        VStack {
                            Spacer(minLength: minDim * 0.55)
                            TextField("Username", text: $nickname)
                                .multilineTextAlignment(.center)
                                .padding()
                                .allowsTightening(true)
                                .font(Font.custom("Galvji", size: 14))
                                .foregroundColor(.gray)
                                .background(
                                    Button {
                                        UIColorWellHelper.helper.execute?()
                                    } label: {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 5)
                                                .fill(Color.white.gradient)
                                                .frame(width: minDim * 0.55, height: 45, alignment: .center)
                                                .shadow(radius: 3)
                                                .zIndex(1)
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(playerColor.gradient)
                                                .frame(width: minDim * 0.75, height: minDim * 0.75, alignment: .center)
                                                .shadow(radius: 3)
                                                .shadow(color: Color(playerColor), radius: 10)
                                                .shadow(color: Color(playerColor), radius: 20)
                                                .shadow(color: Color(playerColor), radius: 30)
                                            ColorPicker("", selection: $playerColor, supportsOpacity: true).labelsHidden().opacity(0.015)
                                        }
                                    }
                                )
                                .disableAutocorrection(true)
                                .onReceive(Just(nickname)) { _ in
                                    limitText(maxLen)
                                }
                            Spacer()
                            Spacer()
                            Text("Tap the square to change color!")
                                .padding()
                                .foregroundStyle(Color(primary_color))
                                .font(Font.custom("Galvji", size: 11))
                            Spacer()
                            Button {
                                if !nickname.isEmpty{
                                    Task.detached {
                                        await updateProfile()
                                    }
                                }
                            } label: {
                                Text("Enter Lobby \(Image(systemName: "arrow.right.circle"))")
                                    .foregroundStyle(.black)
                                    .padding()
                                    .font(Font.custom("Galvji-Bold", size: 14))
                                    .background(
                                        RoundedRectangle(cornerRadius: 10).foregroundStyle(Color(primary_color))
                                            .padding(3)
                                    )
                            }
                            .padding()
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}


#Preview {
   struct PreviewWrapper: View {
       @State var rc: RestController = RestController(host: "127.0.0.1", port:8001)
       @State var vf: ViewFinder = .profile
       var body: some View {
           ProfileView(gameCode: .constant("chunky-rottweiler"), currentView: $vf, restController: $rc)
       }
   }
   return PreviewWrapper()
}

