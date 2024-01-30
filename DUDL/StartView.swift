//
//  StartView.swift
//  DUDL
//
//  Created by Victor on 1/28/24.
//

// When starting a game, all you need is a game code

import Foundation
import SwiftUI

struct StartView : View {
    @State var game_code: String = ""
    @State private var shouldShowAlert: Bool = false
    @State private var alert_message: String = ""
    @Binding var currentView: String
    @Binding var restController: RestController
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            Group {
                if shouldShowAlert {
                    Text("")
                        .alert("Unable to Start Game", isPresented: $shouldShowAlert) {
                            Button("OK", role: .cancel) {
                                game_code = ""
                                currentView = "HomeView"
                            }
                        } message: {
                            Text(alert_message)
                        }
                } else if !game_code.isEmpty {
                    VStack{
                        Text(game_code)
                            .padding()
                            .foregroundStyle(.white)
                            .font(Font.custom("Galvji", size: 25))
                            .onTapGesture {
                                UIPasteboard.general.string = game_code
                                currentView = "HomeView"
                            }
                        ShareLink(item: "Let's DÜDL: \(game_code)") {
                            Label("Share", systemImage:  "arrow.up.circle")
                        }
                        .padding()
                        .foregroundStyle(.white)
                        .font(Font.custom("Galvji", size: 15))
                        
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
        .task {
            await restController.start_new_game { result in
                switch result {
                    case .success(let g):
                    game_code = g.code
                    print("Started a new game \(game_code)")
                    case .failure(let error):
                        switch error {
                            case .serviceUnavailable:
                                alert_message = "Failed to connect to server \n Please check your internet connection"
                            default:
                                alert_message = "Something went wrong \n Please try again later"
                        }
                        shouldShowAlert = true
                        print(error.localizedDescription)
                }
            }
        }
    }
}

#Preview {
   struct PreviewWrapper: View {
       @State var rc: RestController = RestController(host: "127.0.0.1", port:8001)
       var body: some View {
           StartView(currentView: .constant("HomeView"), restController: $rc)
       }
   }
   return PreviewWrapper()
}
