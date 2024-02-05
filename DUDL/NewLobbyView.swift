//
//  NewLobbyView.swift
//  DUDL
//
//  Created by V on 2/3/24.
//

import Foundation
import SwiftUI


struct NewLobbyView : View {
    @Binding var gameCode: String
    @Binding var currentView: String
    @Binding var restController: RestController
    
    @State private var shouldShowAlert: Bool = false
    @State private var alertMessage: String = ""
    
    @State private var playerProfiles: [PlayerProfile] = []
//        PlayerProfile(gameCode: "tangy-cut", playerId: "366E8D01-F323-4BD1-BD67-5D4E50FC4620", nickname: "Abcdefghijklmnopqrst", rgba: RGBA(r: 0.99999994, g: 0.41568625, b: 0, a: 1)),
//        PlayerProfile(gameCode: "tangy-cut", playerId: "366E8D01-F323-4BD1-BD67-5D4E50FC4621", nickname: "Booty", rgba: RGBA(r: 0.999994, g: 0.61568625, b: 1, a: 1)),
//        PlayerProfile(gameCode: "tangy-cut", playerId: "366E8D01-F323-4BD1-BD67-5D4E50FC4622", nickname: "Randy", rgba: RGBA(r: 0.1999994, g: 0.61568625, b: 0.5, a: 1)),
//        
//    ]
    @State private var draggingItem: Color?
    
    func loadAllPlayerProfiles() async {
        await restController.allPlayerProfiles(code: gameCode) { result in
            switch result {
                case .success(let ps):
                    playerProfiles = ps
                    print("Active Players: \(dump(playerProfiles))")
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
        NavigationStack {
            GeometryReader { geo in
                ScrollView(.vertical) {
                    let columns = Array(repeating: GridItem(spacing: 0), count: 1)
                    LazyVGrid(columns: columns, alignment: .center, content: {
                        ForEach(playerProfiles, id: \.playerId) { profile in
                            PlayerProfileGridItemView(size: geo.size, playerProfile: profile)
                        }
                        .padding(50)
                    })
                    
                    .background(Color.black)
                }
            }
            .onTapGesture(count: 2) {
                currentView = "PlayerProfileView"
                let impact = UIImpactFeedbackGenerator(style: .heavy)
                impact.impactOccurred()
            }
            .background(Color.black)
            .task {
                await loadAllPlayerProfiles()
            }
            .refreshable {
                Task.detached {
                    print("Loading All Player Profiles ...")
                    await loadAllPlayerProfiles()
                }
            }
            .toolbar(content: {
                ToolbarItem(placement: .principal) {
                    VStack {
                        let n_playerProfiles = playerProfiles.count
                        Spacer()
                        Text(gameCode).font(.headline).foregroundStyle(.white)
                        Text("\(n_playerProfiles) player\(n_playerProfiles == 1 ? "" : "s")").font(.subheadline).foregroundStyle(.white)
                    }
                }
            })
            .toolbarBackground(.hidden , for: .navigationBar)
        }
        
    }
}


#Preview {
   struct PreviewWrapper: View {
       @State var rc: RestController = RestController(host: "192.168.1.7", port:8001)
       var body: some View {
           NewLobbyView(gameCode: .constant("tangy-cut"), currentView: .constant("NewLobbyView"), restController: $rc)
       }
   }
   return PreviewWrapper()
}
