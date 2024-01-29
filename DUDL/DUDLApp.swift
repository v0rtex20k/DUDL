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
    var body: some Scene {
        WindowGroup {
            switch self.currentView {
                case "ContentView": HomeView(currentView: $currentView)
                case "StartView": StartView(currentView: $currentView)
                default: HomeView(currentView: $currentView)
            }
        }
    }
}
