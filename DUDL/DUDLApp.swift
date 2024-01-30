//
//  DUDLApp.swift
//  DUDL
//
//  Created by Victor on 1/27/24.
//

import SwiftUI

@main
struct DUDLApp: App {
    @State var currentView: String = "ContentView"
    @State var restController: RestController = RestController(host: "192.168.1.5", port: 8001)
    var body: some Scene {
        WindowGroup {
            switch self.currentView {
                case "ContentView": HomeView(currentView: $currentView)
                case "StartView": StartView(currentView: $currentView, restController: $restController)
                default: HomeView(currentView: $currentView)
            }
        }
    }
}
