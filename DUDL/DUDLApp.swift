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
    case start
    case join
    case lobby
    case playerProfile
}

@main
struct DUDLApp: App {
    @State var gameCode: String = ""
    @State var currentView: ViewFinder = .home
    @State var restController: RestController = RestController(host:  "192.168.1.15",
                                                               port: 8001)
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            switch self.currentView {
                case .home: HomeView(currentView: $currentView)
                case .settings: SettingsView(currentView: $currentView, restController: $restController)
                case .start: StartView(gameCode: $gameCode, currentView: $currentView, restController: $restController)
                case .join: JoinView(gameCode: $gameCode, currentView: $currentView, restController: $restController)
                case .lobby: LobbyView(gameCode: $gameCode, currentView: $currentView, restController: $restController)
                case .playerProfile : PlayerProfileView(gameCode: $gameCode, currentView: $currentView, restController: $restController)
            }
        }
    }
}


class AppDelegate: NSObject, UIApplicationDelegate {
        
    static var orientationLock = UIInterfaceOrientationMask.all //By default you want all your views to rotate freely

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}
