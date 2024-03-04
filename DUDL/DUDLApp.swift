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
//    case results
}


var primary_color = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)

@main
struct DUDLApp: App {
    @State var gameCode: String = ""
    @State var currentView: ViewFinder = .home
    @State var restController: RestController = RestController(host: "192.168.1.7",
                                                               port: 8001)
    
    @State var initialPrompt = ""
    
    var body: some Scene {
        WindowGroup {
            switch self.currentView {
//            default:
//                InitialPromptView(prompt: $initialPrompt)
                case .home: HomeView(currentView: $currentView)
                case .settings: SettingsView(currentView: $currentView, restController: $restController)
                case .create: CreateView(gameCode: $gameCode, currentView: $currentView, restController: $restController)
                case .join: JoinView(gameCode: $gameCode, currentView: $currentView, restController: $restController)
                case .lobby: LobbyView(gameCode: $gameCode, currentView: $currentView, restController: $restController)
                case .profile : ProfileView(gameCode: $gameCode, currentView: $currentView, restController: $restController)
                case .arena: ArenaView(gameCode: $gameCode, currentView: $currentView, restController: $restController)
            }
        }
    }
}
