//
//  ArenaView.swift
//  DUDL
//
//  Created by V on 2/10/24.
//

import SwiftUI
import Combine

struct ArenaView: View {
    @State private var alertMessage: String = ""
    @State private var shouldShowAlert: Bool = false
    @State private var shouldShowContent: Bool = true
    let alertTitle = "Unable to Join Game"
    
    @Binding var gameCode: String
    @Binding var nRounds: Int
    @Binding var currentView: ViewFinder
    @Binding var restController: RestController
    
    private let DURATION = 30
    @State private var timeElapsed = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    
    @StateObject var stateMachine : StateMachine = StateMachine()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(edges: .all)
            VStack {
                Spacer()
                stateMachine.stateContent
            }.onReceive(timer) { _ in
                stateMachine.update()
            }
            Spacer()
            Spacer()
        }
        .onAppear() {
            stateMachine.attach(gameCode: gameCode, restController: restController, nRounds: nRounds, roundDuration: DURATION)
            stateMachine.next()
        }
        .onDisappear {
            timer.upstream.connect().cancel()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                VStack {
                    Text("\(DURATION - timeElapsed)")
                        .font(.headline)
                        .foregroundStyle(Color(primary_color))
                        .padding()
                        .border(.red)
                }
            }
        }
    }
}


//#Preview {
//   struct PreviewWrapper: View {
//       @State var rc: RestController = RestController(host: "192.168.1.7", port:8001)
//       @State var vf: ViewFinder = .arena
//       var body: some View {
//           ArenaView(gameCode: .constant("happy-hippo"), currentView: $vf, restController: $rc)
//       }
//   }
//   return PreviewWrapper()
//}
//
//
