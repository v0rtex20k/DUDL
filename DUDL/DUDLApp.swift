//
//  DUDLApp.swift
//  DUDL
//
//  Created by Victor on 1/27/24.
//

import SwiftUI

@main
struct DUDLApp: App {
    @State var gameCode: String = ""
    @State var currentView: String = "HomeView"
    @State var restController: RestController = RestController(host: "127.0.0.1", // "192.168.1.15", 
                                                               port: 8001)
    var body: some Scene {
        WindowGroup {
            switch self.currentView {
                case "HomeView": HomeView(currentView: $currentView)
                case "SettingsView": SettingsView(currentView: $currentView, restController: $restController)
                case "StartView": StartView(gameCode: $gameCode, currentView: $currentView, restController: $restController)
                case "JoinView": JoinView(gameCode: $gameCode, currentView: $currentView, restController: $restController)
                case "LobbyView": NewLobbyView(gameCode: $gameCode, currentView: $currentView, restController: $restController)
                case "PlayerProfileView" : PlayerProfileView(gameCode: $gameCode, currentView: $currentView, restController: $restController)
                default: HomeView(currentView: $currentView)
            }
        }
    }
}
