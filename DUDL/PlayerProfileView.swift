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
    @Binding var currentView: String
    @Binding var restController: RestController
    
    let maxLen = 15
    
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
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                VStack {
                    Spacer()
                    Group {
                        if !wasSubmitted {
                            TextField("Username", text: $nickname)
                                .multilineTextAlignment(.center)
                                .padding()
                                .frame(width: 300, height: 200)
                                .font(Font.custom("Galvji", size: 16))
                                .foregroundColor(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(bgColor.gradient)
                                        .frame(width: 250, height: 250, alignment: .center)
                                        .shadow(radius: 3)
                                        .onTapGesture(count: 1) {
                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
                                        }
                                )
                                .disableAutocorrection(true)
                                .onReceive(Just(nickname)) { _ in
                                    limitText(maxLen)
                                }.padding(25)
                            HStack {
                                Spacer()
                                SquareColorPickerView(colorValue: $bgColor)
                                    .padding()
                                Button("", systemImage: "checkmark.seal"){
                                    let c = bgColor.resolve(in: env)
                                    print("Attempting to update Player Profile \"\(nickname)\", \(c.description) ...")
                                    Task {
                                        await restController.updatePlayerProfile(rgba: RGBA(r: c.red, g: c.green, b: c.blue, a: c.opacity),
                                                                                 nickname: nickname) { result in
                                            wasSubmitted = true
                                            switch result {
                                            case .success(let uppr):
                                                currentView = "LobbyView"
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
                                }
                                .padding()
                                .foregroundStyle(.white)
                                Spacer()
                            }
                        } else if shouldShowAlert {
                            Text("")
                                .alert("Unable to Update Player Profile", isPresented: $shouldShowAlert) {
                                    Button("OK", role: .cancel) {
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
                }
            }
            .onTapGesture(count: 2) {
                currentView = "HomeView"
                let impact = UIImpactFeedbackGenerator(style: .heavy)
                impact.impactOccurred()
            }
        }
    }
}

#Preview {
   struct PreviewWrapper: View {
       @State var rc: RestController = RestController(host: "127.0.0.1", port:8001)
       var body: some View {
           PlayerProfileView(currentView: .constant("PlayerProfileView"), restController: $rc)
       }
   }
   return PreviewWrapper()
}

