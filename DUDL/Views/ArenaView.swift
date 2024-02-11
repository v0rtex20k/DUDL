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
    
    @State var incomingPrompt: String = ""
    @State var incomingDrawing: String = ""
    @State var outgoingPrompt: String = ""
    @State var outgoingDrawing: String = ""
    
    @State var timeLeft: Int = 60
    
    func sendText(_ outText: String) async {
        await restController.sendPrompt(code: gameCode, prompt: outText) { result in
            switch result {
                case .success:
                    outgoingPrompt.removeAll()
                    
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
        GeometryReader { geo in
            BlackDraggableZStack(currentView: $currentView, dragToView: nil, onDragEndFunc: nil) {
                VStack {
                    Spacer()
                    RestfulGroup(currentView: $currentView, gameCode: $gameCode, shouldShowAlert: $shouldShowAlert, alertTitle: alertTitle, alertMessage: alertMessage, shouldShowContent: $shouldShowContent, contentValue: $outgoingPrompt) {data in
                        InitialPromptView(textPrompt: data, startDate: $startDate, timeLeft: $timeLeft, size: geo.size)
                    }
                    Spacer()
                    Spacer()
                    Spacer()
                }
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
    }
}


//#Preview {
//    ArenaView()
//}
