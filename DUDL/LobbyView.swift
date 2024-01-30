//
//  LobbyView.swift
//  DUDL
//
//  Created by V on 1/30/24.
//

import Foundation
import SwiftUI

// 1. POST get-players/{game-code}
// 2. Display all players, allow king to reorder them, updating their turn_indices in the process
// 3. Allow players to edit nicknames by clicking on THEIR icon
// 4. Allow the king to triple-tap other icons to remove them
// 5. King starts the game



struct LobbyView : View {
    @Binding var currentView: String
    @Binding var restController: RestController
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            Text("Lobby")
                .foregroundStyle(.white)
        }.onTapGesture(count: 2) {
            currentView = "HomeView"
            // remove player from the game
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
        }
    }
}

#Preview {
   struct PreviewWrapper: View {
       @State var rc: RestController = RestController(host: "127.0.0.1", port:8001)
       var body: some View {
           LobbyView(currentView: .constant("LobbyView"), restController: $rc)
       }
   }
   return PreviewWrapper()
}

