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
    @State var drawing = "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"
    
    var body: some Scene {
        WindowGroup {
            switch self.currentView {
            default:
                PromptFromDrawingView(drawing: drawing, prompt: $initialPrompt)
//                case .home: HomeView(currentView: $currentView)
//                case .settings: SettingsView(currentView: $currentView, restController: $restController)
//                case .create: CreateView(gameCode: $gameCode, currentView: $currentView, restController: $restController)
//                case .join: JoinView(gameCode: $gameCode, currentView: $currentView, restController: $restController)
//                case .lobby: LobbyView(gameCode: $gameCode, currentView: $currentView, restController: $restController)
//                case .profile : ProfileView(gameCode: $gameCode, currentView: $currentView, restController: $restController)
//                case .arena: ArenaView(gameCode: $gameCode, currentView: $currentView, restController: $restController)
            }
        }
    }
}
