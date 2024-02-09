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
    @State private var draggingItem: Color?
    
    @State private var selfSelect: Bool = false
    
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
        await restController.ejectPlayer(code: gameCode) { result in
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
        BlackDraggableZStack(currentView: $currentView, dragToView: .home, onDragEndFunc: nil) {
            VStack {
                RestfulGroup(currentView: $currentView, gameCode: $gameCode, shouldShowAlert: $shouldShowAlert, alertTitle: alertTitle, alertMessage: alertMessage, shouldShowContent: $shouldShowContent) { code in
                    NavigationStack {
                        GeometryReader { geo in
                            ScrollView(.vertical) {
                                ForEach(playerProfiles, id: \.playerId) { profile in
                                    PlayerProfileGridItemView(size: geo.size, playerProfile: profile)
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                Task.detached {
                                                    selfSelect = await restController.deviceId() == profile.playerId
                                                    await selfSelect ? leaveGame() : eject(profile.playerId)
                                                }
                                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                                impact.impactOccurred()
                                            } label: {
                                                Label(selfSelect ? "Leave" : "Delete", systemImage: selfSelect ? "arrow.turn.up.left" : "trash")
                                            }
                                        }
                                }
                            }
                        }
                        .task {
                            await loadAllPlayerProfiles()
                        }
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
                        })
                        .toolbarBackground(.hidden , for: .navigationBar)
                    }
                }
            }
        }
    }
}
