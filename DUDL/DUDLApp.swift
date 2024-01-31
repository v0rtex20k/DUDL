//
//  DUDLApp.swift
//  DUDL
//
//  Created by Victor on 1/27/24.
//

import SwiftUI

@main
struct DUDLApp: App {
    @State var currentView: String = "HomeView"
    @State var restController: RestController = RestController(host: "192.168.1.14", port: 8001)
    var body: some Scene {
        WindowGroup {
            switch self.currentView {
                case "HomeView": HomeView(currentView: $currentView)
                case "SettingsView": SettingsView(currentView: $currentView, restController: $restController)
                case "StartView": StartView(currentView: $currentView, restController: $restController)
                case "JoinView": JoinView(currentView: $currentView, restController: $restController)
                case "LobbyView": LobbyView(currentView: $currentView, restController: $restController)
                case "PlayerProfileView" : PlayerProfileView(currentView: $currentView, restController: $restController)
                default: HomeView(currentView: $currentView)
            }
        }
    }
}
