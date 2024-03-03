//
//  StateMachine.swift
//  DUDL
//
//  Created by V on 2/18/24.
//

import Foundation
import SwiftUI

enum GameState {
    case notset, initialPrompt, drawFromPrompt, promptFromDrawing
}

class StateMachine: ObservableObject {
    var gameCode: String = ""
    var restController: RestController? = nil
    @Published public var stateContent: AnyView = AnyView(EmptyView())
    
    
    @Published private var state: GameState = .notset
    @Published var inputData: String = ""
    @Published var outputData: String = ""
    
    
    @Published private var alertMessage: String = ""
    @Published private var shouldShowAlert: Bool = false
    @Published private var shouldShowContent: Bool = true
    let alertTitle = "Unable to Submit Your Work"
    
    init() {
        print("Initialized the StateMachine")
    }
    
    func attach(gameCode: String, restController: RestController?) {
        self.gameCode = gameCode
        self.restController = restController!
    }
    
    func pull() async {
        await self.restController?.pull(code: self.gameCode) { result in
            switch result {
                case .success(let jgr):
                    self.inputData = jgr.content
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
    
    func push() async {
        await self.restController?.push(code: self.gameCode, out: self.outputData) { result in
            switch result {
            case .success:
                self.outputData.removeAll()
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

    func next() {
        let inputDataBinding = Binding<String>(
            get: { self.inputData },
            set: {self.inputData = $0 }
        )

        let outputDataBinding = Binding<String>(
            get: {self.outputData },
            set: {self.outputData = $0 }
        )
        
        switch self.state {
            case.notset:
                print("NS --> IP")
                self.state = .initialPrompt
                self.stateContent = AnyView(InitialPromptView(prompt: outputDataBinding))
            case .initialPrompt:
                print("IP --> DFP w/ \(self.inputData) / \(inputDataBinding.wrappedValue)")
                Task.detached {
                    await self.push()
                }
            
                self.state = .drawFromPrompt
                self.stateContent =  AnyView(DrawFromPromptView(prompt: inputDataBinding, drawing: outputDataBinding))
            case .drawFromPrompt:
                print("DFP --> PFD")
                Task.detached {
                    await self.pull()
                    await self.push()
                }
                self.state = .promptFromDrawing
                self.stateContent = AnyView(PromptFromDrawingView(drawing: inputDataBinding, prompt: outputDataBinding))
            case .promptFromDrawing :
                print("PFD --> DFP")
                Task.detached {
                    await self.pull()
                    await self.push()
                }
                self.state = .drawFromPrompt
            self.stateContent = AnyView(DrawFromPromptView(prompt: inputDataBinding, drawing: outputDataBinding))
        }
    }
}
