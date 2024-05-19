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

@MainActor
class StateMachine: ObservableObject {
    private var gameCode: String = ""
    private var nRounds: Int = 0
    private var timeStep: TimeInterval = 0
    private var roundDuration: TimeInterval = 0
    private var restController: RestController? = nil
    
    
    @Published var roundCount: Int = 0
    @Published var timer: AnyCancellable? = nil
    @Published var secondsElapsed: TimeInterval = 0
    @Published var secondsRemaining: TimeInterval = 0
    @Published public var isDone: Bool = false
    @Published public var stateContent: AnyView = AnyView(EmptyView())
    
    @Published var downloadedData: String = ""
    @Published var dataToUpload: String = ""
    @Published private var state: GameState = .notset
    
    @State private var alertMessage: String = ""
    @State private var shouldShowAlert: Bool = false
    @State private var shouldShowContent: Bool = true

    private let alertTitle = "Unable to Submit Your Work"
    
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
        if let download_result = await self.restController?.downloadContent(code: self.gameCode, roundIndex: self.roundCount) {
            await MainActor.run {
                switch download_result {
                case .success(let content):
                    self.downloadedData = content
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
    }
    
    
    func upload() async {
        if let download_result = await self.restController?.uploadContent(code: self.gameCode, data: self.dataToUpload, roundIndex: self.roundCount) {
            await MainActor.run {
                switch download_result {
                    case .success(_):
                        self.dataToUpload.removeAll()
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
    }
    
    func update() {
        print("\t \(roundDuration - secondsElapsed) seconds left in ROUND \(roundCount + 1)/\(nRounds)")
        secondsElapsed += timeStep
        
        if secondsElapsed >= roundDuration {
            print("\tROUND \(roundCount + 1)/\(nRounds) HAS ENDED")
            secondsElapsed = 0
            step()
        }
        
        
    }

    func step() {
        if self.state != .notset {
             print("[\(self.state)] UPLOADING \(self.dataToUpload) ...")
            
            Task.detached {
                await self.upload()     // UPload what YOU did this round
            }
            
            if (self.roundCount + 1) >= self.nRounds {
                self.stop()
                return
            }
            
            self.downloadedData.removeAll()
            Task.detached {
                await self.download()   // DOWNload what your friend did this round
                                        // TODO: retry on failure / no content?
            }
            
             print("[\(self.state)] DOWNLOADED \(self.downloadedData) ...")
            
            print("SWITCHING ROUNDS: \(self.roundCount) --> \(self.roundCount + 1)")
            self.roundCount += 1
        }

        
        switch self.state {
            case.notset:
                print("NS --> IP w/ \(self.downloadedData) / \(self.dataToUpload)")

                self.state = .initialPrompt
                self.stateContent = AnyView(InitialPromptView(stateMachine: self))
            case .initialPrompt:
                print("IP --> DFP w/ \(self.downloadedData) / \(self.dataToUpload)")

                self.state = .drawFromPrompt
                self.stateContent =  AnyView(DrawFromPromptView(stateMachine: self))
            case .drawFromPrompt:
                print("DFP --> PFD w/ \(self.downloadedData) / \(self.dataToUpload)")

                self.state = .promptFromDrawing
                self.stateContent = AnyView(PromptFromDrawingView(stateMachine: self))
            case .promptFromDrawing :
                print("PFD --> DFP w/ \(self.downloadedData) / \(self.dataToUpload)")

                self.state = .drawFromPrompt
                self.stateContent = AnyView(DrawFromPromptView(stateMachine: self))
        }
    }
}
