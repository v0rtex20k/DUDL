//
//  NewLobbyView.swift
//  DUDL
//
//  Created by V on 2/3/24.
//

import Foundation
import SwiftUI


struct LobbyView : View {
    @Binding var gameCode: String
    @Binding var currentView: ViewFinder
    @Binding var restController: RestController
    
    @State private var shouldShowAlert: Bool = false
    @State private var alertMessage: String = ""
    
    @State private var playerProfiles: [PlayerProfile] = []
    @State private var draggingItem: Color?
    
    func loadAllPlayerProfiles() async {
        await restController.allPlayerProfiles(code: gameCode) { result in
            playerProfiles.removeAll()
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
    
    func eject(_ pid: String) async {
        await restController.ejectPlayer(code: gameCode, playerId: pid) { result in
            switch result {
                case .success(let ps):
                    playerProfiles = ps
                    print("Removed \(pid) --> Remaining Players: \(dump(playerProfiles))")
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
                    LazyVStack(alignment: .center, content: {
                        ForEach(playerProfiles, id: \.playerId) { profile in
                            PlayerProfileGridItemView(size: geo.size, playerProfile: profile)
                                .contextMenu {
                                        let selfSelect: Bool = false
//                                    let pid: String = await UIDevice.current.identifierForVendor!.uuidString
//                                    let selfSelect: Bool = profile.playerId == pid
                                    Button(role: .destructive) {
                                        Task.detached {
                                            await eject(profile.playerId)
                                        }
                                        let impact = UIImpactFeedbackGenerator(style: .medium)
                                        impact.impactOccurred()
                                        
//                                        if selfSelect {
//                                            gameCode.removeAll()
//                                            currentView = "HomeView"
//                                        }
                                        
                                    } label: {
                                        Label(selfSelect ? "Leave" : "Delete", systemImage: selfSelect ? "arrow.turn.up.left" : "trash")
                                    }
                                }
                        }
                        .padding(50)
                    })
                    
                    .background(Color.black)
                }
            }
            .onTapGesture(count: 2) {
                currentView = .playerProfile
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


//#Preview {
//   struct PreviewWrapper: View {
//       @State var rc: RestController = RestController(host: "192.168.1.7", port:8001)
//       var body: some View {
//           LobbyView(gameCode: .constant("tangy-cut"), currentView: .constant("LobbyView"), restController: $rc)
//       }
//   }
//   return PreviewWrapper()
//}
