//
//  NewLobbyView.swift
//  DUDL
//
//  Created by V on 2/3/24.
//

import Foundation
import SwiftUI


struct NewLobbyView : View {
    @Binding var gameCode: String
    @Binding var currentView: String
    @Binding var restController: RestController
    
    @State private var shouldShowAlert: Bool = false
    @State private var alertMessage: String = ""
    
    @State private var players: [PlayerProfile] = []
    @State private var draggingItem: Color?
    @State private var zoomIn: Bool = false
    
    func loadAllPlayerProfiles() async {
        await restController.allPlayerProfiles(code: gameCode) { result in
            switch result {
                case .success(let ps):
                players = ps
                print("Active Players: \(dump(players))")
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
        NavigationStack {
            ScrollView(.vertical) {
                let columns = Array(repeating: GridItem(spacing: 10), count: zoomIn ? 2 : 3)
                LazyVGrid(columns: columns, spacing: 10, content: {
                    ForEach(players, id: \.playerId) { player in
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: Double(player.rgba.r),
                                            green: Double(player.rgba.g),
                                            blue: Double(player.rgba.b),
                                            opacity: Double(player.rgba.a)).gradient)
                        }
                        .frame(height: zoomIn ? 200 : 100)
                        
                    }
                }).background(Color.black)
            }
            .task {
                await loadAllPlayerProfiles()
            }
            .refreshable {
                Task.detached {
                    await loadAllPlayerProfiles()
                }
            }
        }
        
    }
}

