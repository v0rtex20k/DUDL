//
//  PlayerProfileView.swift
//  DUDL
//
//  Created by V on 1/30/24.
//

import Foundation
import Combine
import SwiftUI

struct PlayerProfileView : View {
    @Binding var gameCode: String
    @Binding var currentView: ViewFinder
    @Binding var restController: RestController
    
    private let maxLen = 20
    private let alertTitle = "Unable to create Player Profile"
    
    @State var nickname: String = ""
    @State private var bgColor = Color.blue
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
        let c = bgColor.resolve(in: env)
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
    
    
    var body: some View {
        GeometryReader { geo in
            let minDim = min(geo.size.width, geo.size.height)
            BlackDraggableZStack(currentView: $currentView, dragToView: .home) {
                VStack {
                    RestfulGroup(currentView: $currentView, gameCode: $gameCode, shouldShowAlert: $shouldShowAlert, alertTitle: alertTitle, alertMessage: alertMessage, shouldShowContent: $shouldShowContent) { code in
                        VStack {
                            Spacer(minLength: minDim * 0.4)
                            TextField("Username", text: $nickname)
                                .multilineTextAlignment(.center)
                                .padding()
                                .allowsTightening(true)
                                .font(Font.custom("Galvji", size: 16))
                                .foregroundColor(.gray)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(Color.white.gradient)
                                            .frame(width: minDim * 0.7, height: 45, alignment: .center)
                                            .shadow(radius: 3)
                                            .zIndex(1)
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(bgColor.gradient)
                                            .frame(width: minDim * 0.8, height: minDim * 0.8, alignment: .center)
                                            .shadow(radius: 3)
                                            .onTapGesture(count: 1) {
                                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
                                            }
                                    }
                                )
                                .disableAutocorrection(true)
                                .onReceive(Just(nickname)) { _ in
                                    limitText(maxLen)
                                }
                            Spacer()
                            HStack {
                                Spacer()
                                SquareColorPickerView(colorValue: $bgColor)
                                    .padding()
                                Button("", systemImage: "checkmark.seal"){
                                    if !nickname.isEmpty{
                                        Task.detached {
                                            await updateProfile()
                                        }
                                    }
                                }
                                .padding()
                                .foregroundStyle(.white)
                                .overlay(RoundedRectangle(cornerRadius: 5.0).stroke(Color.white, style: StrokeStyle(lineWidth: 3)))
                                .padding(10)
                                
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                }
                
            }
        }
    }
}

//#Preview {
//   struct PreviewWrapper: View {
//       @State var rc: RestController = RestController(host: "192.168.1.7", port:8001)
//       var body: some View {
//           PlayerProfileView(gameCode: .constant("happy-hippo"), currentView: .constant("PlayerProfileView"), restController: $rc)
//       }
//   }
//   return PreviewWrapper()
//}

