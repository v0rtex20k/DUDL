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
    
    @State var nickname: String = ""
    @State private var bgColor = Color.blue
    @State private var alertMessage: String = ""
    @State private var wasSubmitted: Bool = false
    @State private var shouldShowAlert: Bool = false
    
    @Environment(\.self) var env
    
    func limitText(_ upper: Int) {
        if nickname.count > upper {
            nickname = String(nickname.prefix(upper))
        }
    }
    
    func updateProfile() async {
        let c = bgColor.resolve(in: env)
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
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                VStack {
                    Spacer(minLength: minDim * 0.4)
                    Group {
                        if !wasSubmitted {
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
                                Spacer()
                            }
                            Spacer()
                        } else if shouldShowAlert {
                            Text("")
                                .alert("Unable to Update Player Profile", isPresented: $shouldShowAlert) {
                                    Button("OK", role: .cancel) {
                                        gameCode.removeAll()
                                        currentView = .home
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
                }
            }
            .onTapGesture(count: 2) {
                gameCode.removeAll()
                currentView = .home
                let impact = UIImpactFeedbackGenerator(style: .heavy)
                impact.impactOccurred()
            }
            .onTapGesture(count: 1) {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
            }
        }.ignoresSafeArea(.keyboard)
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

