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
    
    private let roundDuration: TimeInterval = 30
    private let timeStep: TimeInterval = 0.5
    @State private var timeElapsed: TimeInterval = 0

    @ObservedObject var stateMachine : StateMachine = StateMachine()
    
    func debug() async {
        await self.restController.debug(code: self.gameCode) { result in
            switch result {
                case .success:
                    print("DEBUG MODE ACTIVATED")
                case .failure(let error):
                    switch error {
                        case .serviceUnavailable:
                            self.alertMessage = "Failed to connect to server \n Please check your internet connection"
                        default:
                            self.alertMessage = "Something went wrong \n Please try again later"
                    }
                    self.shouldShowAlert = true
                    print(error.localizedDescription)
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(edges: .all)
            VStack {
                Spacer()
                stateMachine.stateContent
                .onChange(of: stateMachine.isDone) {
                    print("The \(gameCode) Game is complete")
                    currentView = .end
                }
            }
            Spacer()
            Spacer()
        }
        .onAppear() {
            print("STARTED! :)")
            stateMachine.start(gameCode: gameCode, restController: restController, nRounds: nRounds, timeStep: timeStep, roundDuration: roundDuration)
        }
    }
}


#Preview {
   struct PreviewWrapper: View {
       @State var rc: RestController = RestController(host: "192.168.1.10", port:8001)
       @State var vf: ViewFinder = .arena
       
       var body: some View {
           let ar = ArenaView(gameCode: .constant("happy-hippo"), nRounds: .constant(2), currentView: $vf, restController: $rc)
           ar.onAppear {
               Task {
                   await ar.debug()
               }
           }
       }
   }
   return PreviewWrapper()
}
