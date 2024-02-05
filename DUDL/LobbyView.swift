//
//  LobbyView.swift
//  DUDL
//
//  Created by V on 1/30/24.
//

import Foundation
import SwiftUI

// 1. POST get-players/{game-code}
// 2. Display all players, allow king to reorder them for fun
// 3. Allow players to edit nicknames by clicking on THEIR icon
// 4. Allow the king to triple-tap other icons to remove them
// 5. King starts the game


struct LobbyView : View {
    @Binding var currentView: String
    @Binding var restController: RestController
    
    @State private var colors: [Color] = [.red, .blue, .purple,
        .yellow, .black, .indigo, .cyan, .brown, .mint, .orange]
    @State private var draggingItem: Color?
    @State private var zoomIn: Bool = false
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                let columns = Array(repeating: GridItem(spacing: 10), count: zoomIn ? 2 : 3)
                LazyVGrid(columns: columns, spacing: 10, content: {
                    ForEach(colors, id: \.self) { color in
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 10)
                                .fill(color.gradient)
                                /// Drag
                                .draggable(color) {
                                    /// Custom Preview View
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.ultraThinMaterial)
                                        .frame(width: geo.size.width, height: geo.size.height)
                                        .onAppear {
                                            draggingItem = color
                                        }
                                }
                                /// Drop
                                .dropDestination(for: Color.self) { items, location in
                                    draggingItem = nil
                                    return false
                                } isTargeted: { status in
                                    if let draggingItem, status, draggingItem != color {
                                        /// Moving Color from source to destination
                                        if let sourceIndex = colors.firstIndex(of: draggingItem),
                                           let destinationIndex = colors.firstIndex(of: color) {
                                            withAnimation(.bouncy) {
                                                let sourceItem = colors.remove(at: sourceIndex)
                                                colors.insert(sourceItem, at: destinationIndex)
                                            }
                                        }
                                    }
                                }
                                .onTapGesture {
                                    
                                }
                                .onTapGesture(count: 3) {
                                    print("delete \(color) player!")
                                    // NOTE: remove player from the game
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                }

                        }
                        .frame(height: zoomIn ? 200 : 100)
                    }
                })
                .padding(15)
                .background(Color.black)
            }
            .onAppear {
                currentView = "NewLobbyView"
            }
            .onTapGesture(count: 2) {
                currentView = "PlayerProfileView"
                let impact = UIImpactFeedbackGenerator(style: .heavy)
                impact.impactOccurred()
            }
            .background(Color.black)
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.bouncy) {
                            zoomIn.toggle()
                        }
                    } label: {
                        Image(systemName: zoomIn ? "minus.magnifyingglass" : "plus.magnifyingglass")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }
            })
            .toolbarBackground(.hidden , for: .navigationBar)
        }
    }
}

#Preview {
   struct PreviewWrapper: View {
       @State var rc: RestController = RestController(host: "192.168.1.15", port:8001)
       var body: some View {
           LobbyView(currentView: .constant("LobbyView"), restController: $rc)
       }
   }
   return PreviewWrapper()
}

