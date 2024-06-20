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
    @Binding var playerCount: Int
    @Binding var currentView: ViewFinder
    @Binding var restController: RestController

    @State private var shouldShowContent: Bool = true

    @State private var shouldShowAlert: Bool = false
    @State private var alertMessage: String = ""
    let alertTitle = "Connection Lost"

    @State private var playerProfiles: [PlayerProfile] = [
    PlayerProfile(gameCode: "happy-hippo", playerId: "123", nickname: "ghost", rgba: RGBA(r: 0, g: 0, b: 0, a: 0))
    ]
    @State private var deviceUUID: String = ""
    @State private var isHost: Bool = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    func loadAllPlayerProfiles() async {
        if !gameCode.isEmpty {
            await restController.allPlayerProfiles(code: gameCode) { result in
                playerProfiles.removeAll()
                switch result {
                case .success(let ps):
                                        playerProfiles = [PlayerProfile(gameCode: gameCode, playerId: "fakeId", nickname: "Ghost", rgba: RGBA(r: 0, g: 0, b: 0, a: 1) )]
                    playerProfiles.append(contentsOf: ps)
                    
                    for p in playerProfiles {
                        if (p.isHost ?? false) && p.playerId == deviceUUID {
                            isHost = true
                        }
                    }
                    
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
    }

    
    func leaveGame() async {
        await restController.removePlayer(code: gameCode) { result in
            switch result {
            case .success:
                timer.upstream.connect().cancel()
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
                case .success:
                    playerProfiles = playerProfiles.filter(){p in p.playerId == pid}
                    timer.upstream.connect().cancel()
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
    
    func pollGameStatus() {
        // you can't play by yourself :)
        if !gameCode.isEmpty && playerProfiles.count > 1 {
            Task {
                await restController.gameStatus(code: gameCode) { result in
                    switch result {
                    case .success(let gsr):
                        if gsr.started {
                            print("LET THE GAMES BEGIN")
                            playerCount = playerProfiles.count
                            timer.upstream.connect().cancel()
                            currentView = .arena
                        } else {
                            print("Still waiting for the game to start ...")
                        }
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
                
    }
    
    func startGame() async {
        // you can't play by yourself :)
        if playerProfiles.count > 1 {
            await restController.startGame(code: gameCode) { result in
                switch result {
                    case .success:
                        playerCount = playerProfiles.count
                        timer.upstream.connect().cancel()
                        currentView = .arena
                        print("THE GAME HAS BEEN STARTED")
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
        BlackDraggableZStack(currentView: $currentView, dragToView: .profile, onDragEndFunc: nil) {
            RestfulGroup(currentView: $currentView, gameCode: $gameCode, shouldShowAlert: $shouldShowAlert, alertTitle: alertTitle, alertMessage: alertMessage, shouldShowContent: $shouldShowContent, contentValue: $gameCode) { code in
                NavigationStack {
                    GeometryReader { geo in
                        ScrollView(.vertical) {
                            ForEach(playerProfiles, id: \.playerId) {profile in
                                let selfSelect = deviceUUID == profile.playerId
                                ProfileCardView(size: geo.size, playerProfile: profile)
                                    .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 10))
                                    .contextMenu {
                                        if selfSelect || isHost {
                                            Button(role: .destructive) {
                                                print("\(deviceUUID) VS \(profile.playerId)")
                                                Task {
                                                    await selfSelect ? leaveGame() : eject(profile.playerId)
                                                }
                                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                                impact.impactOccurred()
                                            } label: {
                                                Label(selfSelect ? "Leave Game" : "Remove \"\(profile.nickname)\" from Game", systemImage: selfSelect ? "arrow.turn.up.left" : "xmark.octagon.fill")
                                            }
                                        }
                                    }
                                    preview: {
                                        ProfileCardView(size: geo.size, playerProfile: profile)
                                            .background(Color.black).ignoresSafeArea(.all)
                                        
                                    }
                                Spacer()
                            }
                        }
                    }
                    .task {
                        deviceUUID = await restController.deviceId()
                        await loadAllPlayerProfiles()
                    }
                    .onReceive(timer) { _ in
                        pollGameStatus()
                        Task.detached{
                            await loadAllPlayerProfiles()
                        }
                    }
                    .onDisappear {
                        timer.upstream.connect().cancel()
                    }
                    .background(Color.black)
                    .refreshable {
                        print("Loading All Player Profiles ...")
                        await loadAllPlayerProfiles()
                    }
                    .toolbar {
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
                            if isHost {
                                Button {
                                    Task {
                                        await startGame()
                                    }
                                } label : {
                                    Text("Let's DÜDL!")
                                        .font(.headline)
                                        .shadow(color: Color(primary_color), radius: 10)
                                        .shadow(color: Color(primary_color), radius: 15)
                                        .foregroundStyle(Color(primary_color))
                                }
                            }
                        }
                    }
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
           LobbyView(gameCode: .constant("happy-hippo"), playerCount: .constant(2), currentView: $vf, restController: $rc)
       }
   }
   return PreviewWrapper()
}

