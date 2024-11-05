//
//  PlayerProfileGridItemView.swift
//  DUDL
//
//  Created by V on 2/5/24.
//

import Foundation
import SwiftUI

struct ProfileCardView : View {
    @State var size: CGSize
    @State var playerProfile: PlayerProfile

    var body : some View {
        ZStack {
            Color.clear.edgesIgnoringSafeArea(.all)
            let dim = min(size.width, size.height)
            Text(playerProfile.nickname)
                .padding()
                .foregroundStyle(.black)
                .allowsTightening(true)
                .multilineTextAlignment(.center)
                .font(Font.custom("Galvji", size: 14))
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(primary_color).gradient)
                        .shadow(radius: 3)
                        .zIndex(1)
                        .frame(width: dim * 0.55, height: dim * 0.125, alignment: .center)
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: Double(playerProfile.rgba.r),
                                                            green: Double(playerProfile.rgba.g),
                                                            blue: Double(playerProfile.rgba.b),
                                                            opacity: Double(playerProfile.rgba.a))
                                                    .gradient)
                        .frame(width: dim * 0.75, height: dim * 0.18, alignment: .center)
                }
                .frame(width: dim, alignment: .center)
                .frame(height: dim * 0.225)
        }
    }
}

#Preview {
   struct PreviewWrapper: View {
       @State var rc: RestController = RestController(host: "192.168.1.7", port:8001)
       @State var vf: ViewFinder = .lobby
       var body: some View {
           LobbyView(gameCode: .constant("happy-hippo"), playerCount: .constant(2), currentView: $vf, restController: $rc)
       }
   }
   return PreviewWrapper()
}

