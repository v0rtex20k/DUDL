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
    
    @State private var shouldShowContent: Bool = true
    
    @State private var shouldShowAlert: Bool = false
    @State private var alertMessage: String = ""
    let alertTitle = "Connection Lost"
    
    @State private var playerProfiles: [PlayerProfile] = []
    
    @State private var deviceUUID: String = ""
    
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

    
    func leaveGame() async {
        await restController.removePlayer(code: gameCode) { result in
            switch result {
            case .success:
                currentView = .lobby
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
    
    
    func eject(_ pid: String) async {
        await restController.removePlayer(code: gameCode, playerId: pid) { result in
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
    
    func poll() {
        // can't play by yourself :)
        if playerProfiles.count > 1 {
            await restController.gameStatus(code: gameCode) { result in
                switch result {
                case .success(let gsr):
                    if gsr.started {
                        currentView = .arena
                    }
                    print("LET THE GAMES BEGIN")
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
    
    var body: some View {
        BlackDraggableZStack(currentView: $currentView, dragToView: .playerProfile, onDragEndFunc: nil) {
            RestfulGroup(currentView: $currentView, gameCode: $gameCode, shouldShowAlert: $shouldShowAlert, alertTitle: alertTitle, alertMessage: alertMessage, shouldShowContent: $shouldShowContent) { code in
                NavigationStack {
                    GeometryReader { geo in
                        ScrollView(.vertical) {
                            ForEach(playerProfiles, id: \.playerId) { profile in
                                ProfileCardView(size: geo.size, playerProfile: profile)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            print("\(deviceUUID) VS \(profile.playerId)")
                                            Task.detached {
                                                await deviceUUID == profile.playerId ? leaveGame() : eject(profile.playerId)
                                            }
                                            let impact = UIImpactFeedbackGenerator(style: .medium)
                                            impact.impactOccurred()
                                        } label: {
                                            let selfSelect = deviceUUID == profile.playerId
                                            Label(selfSelect ? "Leave Game" : "Remove \"\(profile.nickname)\" from Game", systemImage: selfSelect ? "arrow.turn.up.left" : "xmark.octagon.fill")
                                        }
                                    } preview: {
                                        let dim = min(geo.size.width, geo.size.height)
                                        ProfileCardView(size: geo.size, playerProfile: profile)
                                            .frame(width: dim, height: dim * 0.3, alignment: .center)
                                    }
                            }
                        }
                    }
                    .task {
                        deviceUUID = await restController.deviceId()
                        await loadAllPlayerProfiles()
                        Timer.scheduledTimer(
                                    withTimeInterval: 5,
                                    repeats: true
                                ) { _ in
                                    poll()
                                }
                    }
                    .background(Color.black)
                    .refreshable {
                        print("Loading All Player Profiles ...")
                        await loadAllPlayerProfiles()
                    }
                    .toolbar(content: {
                        ToolbarItem(placement: .principal) {
                            VStack {
                                let np = playerProfiles.count
                                Spacer()
                                Text(gameCode)
                                    .font(.headline).foregroundStyle(Color(primary_color))
                                Text("\(np) player\(np == 1 ? "" : "s")")
                                    .font(.subheadline).foregroundStyle(Color(primary_color))
                            }
                        }
                        ToolbarItem(placement: .bottomBar) {
                            Button {
                                print("KICK OFF GAME")
                            } label : {
                                Text("Let's DÜDL!")
                                .font(.headline)
                                .shadow(color: Color(primary_color), radius: 6)
                                .shadow(color: Color(primary_color), radius: 8)
                                .foregroundStyle(Color(primary_color))
                            }
                        }
                    })
                    .toolbarBackground(.hidden, for: .navigationBar)
                    .toolbarBackground(.hidden, for: .bottomBar)

                }
                .toolbarBackground(.hidden)

            }
        }
    }
}

#Preview {
   struct PreviewWrapper: View {
       @State var rc: RestController = RestController(host: "192.168.1.7", port:8001)
       @State var vf: ViewFinder = .lobby
       var body: some View {
           LobbyView(gameCode: .constant("happy-hippo"), currentView: $vf, restController: $rc)
       }
   }
   return PreviewWrapper()
}

