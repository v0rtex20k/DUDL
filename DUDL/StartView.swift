//
//  StartView.swift
//  DUDL
//
//  Created by Victor on 1/28/24.
//

// When starting a game, all you need is a game code

import Foundation
import SwiftUI

func start_game() async throws -> Game {
    
    let default_game: Game = Game(id: "-1", players: [])
    print("Querying http://localhost:5000 ...")
    guard let url = URL(string: "http://127.0.0.1:5000") else { return default_game }
    
    let (data, _) = try await URLSession.shared.data(from: url)
    
    print("Got " , data.map { String(format: "%02x", $0) }.joined())

    let decoded: Game = try JSONDecoder().decode(Game.self, from: data)
    
    return decoded
}

struct StartView : View {
    @State var game: Game?
    @Binding var currentView: String
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            Text(game?.id ?? "unknown")
                .foregroundStyle(.white)
                .padding()
                .font(Font.custom("Galvji", size: 30))
                .foregroundStyle(.white)
        }.task {
            do {
                game = try await start_game()
            } catch {
                print(game)
                print("error: ", error)
            }
        }
    }
}

#Preview {
    StartView(currentView: .constant("HomeView"))
}
