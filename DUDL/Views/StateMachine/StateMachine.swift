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
    
    @Published private var state: GameState = .notset
    @Published var downloadData: String = ""
    @Published var uploadData: String = ""
    
    
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

    
    func download() async {
        await self.restController?.downloadContent(code: self.gameCode, roundIndex: self.roundCount) { result in
            switch result {
                case .success(let content):
                    self.downloadData = content
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
    
    func upload() async {
        await self.restController?.uploadContent(code: self.gameCode, data: self.uploadData, roundIndex: self.roundCount) { result in
            switch result {
            case .success:
                self.uploadData.removeAll()
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
        print("\t \(self.roundDuration - self.secondsElapsed) seconds left in ROUND \(self.roundCount + 1)/\(self.nRounds)")
        self.secondsElapsed += self.timeStep
        
        if self.secondsElapsed >= self.roundDuration {
            print("\tROUND \(self.roundCount + 1)/\(self.nRounds) HAS ENDED")
            self.secondsElapsed = 0
            self.step()
        }
        
        
    }

    func step() {
        let downloadDataBinding = Binding<String>(
            get: {self.downloadData},
            set: {self.downloadData = $0}
        )

        let uploadDataBinding = Binding<String>(
            get: {self.uploadData},
            set: {self.uploadData = $0}
        )
        
        if self.state != .notset {
            // print("[\(self.state)] UPLOADING \(self.uploadData) ...")
            
            Task.detached {
                await self.upload()     // UPload what YOU did this round
                                        // TODO: retry on failure / no content?
            }
            
            if (self.roundCount + 1) >= self.nRounds {
                self.stop()
                return
            }
            
            Task.detached {
                await self.download()   // DOWNload what your friend did this round
                                        // TODO: retry on failure / no content?
            }
            
            // print("[\(self.state)] DOWNLOADED \(self.downloadData) ...")
            
            print("SWITCHING ROUNDS: \(self.roundCount) --> \(self.roundCount + 1)")
            self.roundCount += 1
        }

        
        switch self.state {
            case.notset:
                print("NS --> IP")

                self.state = .initialPrompt
                self.stateContent = AnyView(InitialPromptView(prompt: uploadDataBinding))
            case .initialPrompt:
                print("IP --> DFP w/ \(self.downloadData) / \(downloadDataBinding.wrappedValue)")

                self.state = .drawFromPrompt
                self.stateContent =  AnyView(DrawFromPromptView(prompt: downloadDataBinding, drawing: uploadDataBinding))
            case .drawFromPrompt:
                print("DFP --> PFD w/ \(self.downloadData) / \(downloadDataBinding.wrappedValue)")

                self.state = .promptFromDrawing
                self.stateContent = AnyView(PromptFromDrawingView(drawing: downloadDataBinding, prompt: uploadDataBinding))
            case .promptFromDrawing :
                print("PFD --> DFP w/ \(self.downloadData) / \(downloadDataBinding.wrappedValue)")

                self.state = .drawFromPrompt
                self.stateContent = AnyView(DrawFromPromptView(prompt: downloadDataBinding, drawing: uploadDataBinding))
        }
    }
}
