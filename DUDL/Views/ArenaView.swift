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
    
    @State private var stateMachine: StateMachine? = nil
    
    
    @State var timeLeft: Int = 60
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(edges: .all)
            VStack {
                Spacer()
                RestfulGroup(currentView: $currentView, gameCode: $gameCode, shouldShowAlert: $shouldShowAlert, alertTitle: alertTitle, alertMessage: alertMessage, shouldShowContent: $shouldShowContent, contentValue: .constant("")) {data in
                    stateMachine?.view
                        .onReceive(timer) { firedDate in
                            timeLeft = Int(firedDate.timeIntervalSince(startDate)) // seconds
                            print("\t \(timeLeft) seconds left in ROUND")
                            if timeLeft == 0 {
                                print("\t ROUND IS OVER")
                                stateMachine?.step()
                                timeLeft = 60
                            }
                        }
                }
                Spacer()
                Spacer()
                Spacer()
            }
        }
//        .onAppear {
//            stateMachine = StateMachine(gameCode: gameCode, restController: restController)
//        }
//        .onDisappear {
//            timer.upstream.connect().cancel()
//        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                VStack {
                    Text("\(timeLeft)")
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
