//
//  DUDLApp.swift
//  DUDL
//
//  Created by Victor on 1/27/24.
//

import SwiftUI


enum ViewFinder {
    case home
    case settings
    case create
    case join
    case profile
    case lobby
    case arena
    case end
//    case results
}


var primary_color = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)

@main
struct DUDLApp: App {
    @State var gameCode: String = ""
    @State var playerCount: Int = 0
    @State var currentView: ViewFinder = .home
    @State var restController: RestController = RestController(host: "127.0.0.1",
//                                                              "192.168.1.37",
                                                                port: 8001)

    var body: some Scene {
        WindowGroup {
            switch self.currentView {
                case .home: HomeView(currentView: $currentView)
                case .settings: SettingsView(currentView: $currentView, restController: $restController)
                case .create: CreateView(gameCode: $gameCode, currentView: $currentView, restController: $restController)
                case .join: JoinView(gameCode: $gameCode, currentView: $currentView, restController: $restController)
                case .profile : ProfileView(gameCode: $gameCode, currentView: $currentView, restController: $restController)
                case .lobby: LobbyView(gameCode: $gameCode, playerCount: $playerCount, currentView: $currentView, restController: $restController)
                case .arena: ArenaView(gameCode: $gameCode, nRounds: $playerCount, currentView: $currentView, restController: $restController)
                case .end: EndView(gameCode: $gameCode, currentView: $currentView, restController: $restController)
            }
        }
    }
}
