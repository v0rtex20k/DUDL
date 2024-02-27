//
//  ArenaView.swift
//  DUDL
//
//  Created by V on 2/10/24.
//

import SwiftUI
import Combine

struct ArenaView: View {
    @State var startDate: Date = Date.now
    @State private var alertMessage: String = ""
    @State private var shouldShowAlert: Bool = false
    @State private var shouldShowContent: Bool = true
    let alertTitle = "Unable to Join Game"
    
    @Binding var gameCode: String
    @Binding var currentView: ViewFinder
    @Binding var restController: RestController
    
    private let DURATION = 6
    @State private var timeElapsed = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    
    @StateObject var stateMachine : StateMachine = StateMachine()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(edges: .all)
            VStack {
                Spacer()
//                RestfulGroup(currentView: $currentView, gameCode: $gameCode, shouldShowAlert: $shouldShowAlert, alertTitle: alertTitle, alertMessage: alertMessage, shouldShowContent: $shouldShowContent, contentValue: .constant("")) {data in
//                    stateMachine.view
                stateMachine.stateContent
                }.onReceive(timer) { firedDate in
                    timeElapsed = Int(firedDate.timeIntervalSince(startDate)) // seconds
                    print("\t \(DURATION - timeElapsed) seconds left in ROUND")
                    if timeElapsed >= DURATION {
                        print("\t ROUND IS OVER")
                        startDate = Date.now
                        timeElapsed = 0
                        stateMachine.next()
                    }
                }
                Spacer()
                Spacer()
//            }
        }
        .onAppear() {
            stateMachine.attach(gameCode: gameCode, restController: restController)
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
//    ArenaView()
//}
