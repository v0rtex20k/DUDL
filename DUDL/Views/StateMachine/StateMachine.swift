//
//  StateMachine.swift
//  DUDL
//
//  Created by V on 2/18/24.
//

import Foundation
import SwiftUI

enum GameState {
    case initialPrompt
    case drawFromPrompt
    case promptFromDrawing
}

struct StateMachine {
    let gameCode: String
    let restController: RestController
    @State private var state: GameState = .initialPrompt // always start w initial prompt
    @State var inputData: String = ""
    @State var outputData: String = ""
    @State var view: AnyView = AnyView(EmptyView())
    
    
    @State var startDate: Date = Date.now
    @State private var alertMessage: String = ""
    @State private var shouldShowAlert: Bool = false
    @State private var shouldShowContent: Bool = true
    let alertTitle = "Unable to Submit Your Work"
    
    init(gameCode: String, restController: RestController) {
        self.gameCode = gameCode
        self.restController = restController
        self.view = AnyView(InitialPromptView(textPrompt: $inputData))
    }
    
    func pull() async {
        await self.restController.pull(code: self.gameCode) { result in
            switch result {
                case .success(let jgr):
                    self.inputData = jgr
                    self.step()
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
    
    func push() async {
        await self.restController.push(code: self.gameCode, out: self.outputData) { result in
            switch result {
            case .success:
                self.outputData = ""
                self.step()
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
    
    func step() {
        switch self.state {
            case .initialPrompt:
                Task.detached {
                    await self.push()
                }
                self.state = .drawFromPrompt
                self.view  = AnyView(DrawFromPromptView())
            case .drawFromPrompt:
                Task.detached {
                    await self.pull()
                    await self.push()
                }
                self.state = .promptFromDrawing
                self.view  = AnyView(PromptFromDrawingView())
            case .promptFromDrawing :
                Task.detached {
                    await self.pull()
                    await self.push()
                }
                self.state = .drawFromPrompt
                self.view  = AnyView(DrawFromPromptView())
        }
    }
}
