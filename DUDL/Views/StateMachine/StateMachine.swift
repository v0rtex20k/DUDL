//
//  StateMachine.swift
//  DUDL
//
//  Created by V on 2/18/24.
//

import Combine
import Foundation
import SwiftUI

enum GameState {
    case notset, initialPrompt, drawFromPrompt, promptFromDrawing
}

class StateMachine: ObservableObject {
    var gameCode: String = ""
    var nRounds: Int = 0
    var roundCount: Int = 0
    var timer: AnyCancellable? = nil
    var roundDuration: TimeInterval = 0
    var timeStep: TimeInterval = 0
    var secondsElapsed: TimeInterval = 0
    var restController: RestController? = nil
    
    @Published public var isDone: Bool = false
    @Published public var stateContent: AnyView = AnyView(EmptyView())
    
    
    @State private var advance: Bool = false
    
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
    
    func start(gameCode: String, restController: RestController?, nRounds: Int, timeStep: TimeInterval, roundDuration: TimeInterval) {
        self.nRounds = nRounds
        self.roundDuration = roundDuration
        self.timeStep = timeStep
        self.gameCode = gameCode
        self.restController = restController!
    
        print("STARTING THE TIMER!")
        
        self.step()
        self.timer = Timer.publish(every: self.timeStep, on: .main, in: .common).autoconnect().sink {_ in
            print("UPDATING THE SM!")
            self.update()
        }
        
    }
    
    func stop() {
        print("STOPPING THE TIMER!")
        self.timer!.cancel()
        self.isDone = true
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
    
    func update() {
        print("\t \(self.roundDuration - self.secondsElapsed) seconds left in ROUND")
        self.secondsElapsed += self.timeStep
        if self.secondsElapsed > self.roundDuration {
            print("\tENDING ROUND \(self.roundCount + 1)/\(self.nRounds)")
            self.roundCount += 1
            self.secondsElapsed = 0
            self.step()
        }
        
        if self.roundCount >= self.nRounds {
            self.stop()
        }
    }

    func step() {
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
                self.stateContent = AnyView(InitialPromptView(prompt: outputDataBinding, advance: $advance))
                
            case .initialPrompt:
                print("IP --> DFP w/ \(self.inputData) / \(inputDataBinding.wrappedValue)")
                Task.detached {
                    await self.push()
                }
            
                self.state = .drawFromPrompt
                self.stateContent =  AnyView(DrawFromPromptView(prompt: inputDataBinding, drawing: outputDataBinding, advance: $advance))
            case .drawFromPrompt:
                print("DFP --> PFD")
                Task.detached {
                    await self.pull()
                    await self.push()
                }
                self.state = .promptFromDrawing
            self.stateContent = AnyView(PromptFromDrawingView(drawing: inputDataBinding.wrappedValue, prompt: outputDataBinding, advance: $advance))
            case .promptFromDrawing :
                print("PFD --> DFP")
                Task.detached {
                    await self.pull()
                    await self.push()
                }
                self.state = .drawFromPrompt
                self.stateContent = AnyView(DrawFromPromptView(prompt: inputDataBinding, drawing: outputDataBinding, advance: $advance))
        }
    }
}
