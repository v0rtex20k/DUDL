//
//  PlayerProfileGridItemView.swift
//  DUDL
//
//  Created by V on 2/5/24.
//

import Foundation
import SwiftUI


struct PlayerProfileGridItemView : View {
    @State var size: CGSize
    @State var playerProfile: PlayerProfile
    var body : some View {
        ZStack {
            let minDim = min(size.width, size.height)
            Text(playerProfile.nickname)
                .padding()
                .foregroundStyle(.black)
                .allowsTightening(true)
                .multilineTextAlignment(.center)
                .font(Font.custom("Galvji", size: 14))
                .background {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(primary_color).gradient)
                        .shadow(radius: 3)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 25)
                        .zIndex(1)
                        .frame(width: minDim * 0.71, height: minDim * 0.25)
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: Double(playerProfile.rgba.r),
                                    green: Double(playerProfile.rgba.g),
                                    blue: Double(playerProfile.rgba.b),
                                    opacity: Double(playerProfile.rgba.a))
                            .gradient)
                        .frame(width: minDim * 0.75, height: minDim * 0.3)
                }.frame(width: size.width)
        }
    }
}

//#Preview {
//   struct PreviewWrapper: View {
//       @State var rc: RestController = RestController(host: "192.168.1.7", port:8001)
//       var body: some View {
//           LobbyView(gameCode: .constant("tangy-cut"), currentView: .constant("LobbyView"), restController: $rc)
//       }
//   }
//   return PreviewWrapper()
//}
