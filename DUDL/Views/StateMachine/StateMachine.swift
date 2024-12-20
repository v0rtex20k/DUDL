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
    private var roundDurations: [GameState: TimeInterval] = [GameState: TimeInterval]()
    private var restController: RestController? = nil
    
    private let defaultRoundDuration: TimeInterval = 30
    
    @Published var roundCount: Int = 0
    @Published var timer: AnyCancellable? = nil
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
        // print("Initialized the StateMachine")
    }
    
    func start(gameCode: String, restController: RestController?, nRounds: Int, timeStep: TimeInterval, roundDurations: [GameState: TimeInterval]) {
        self.nRounds = nRounds
        self.roundDurations = roundDurations
        self.timeStep = timeStep
        self.gameCode = gameCode
        self.restController = restController!
        
        self.secondsRemaining = self.roundDurations[self.state, default: defaultRoundDuration]
    
        // print("STARTING THE TIMER!")
        
        self.step()
        self.timer = Timer.publish(every: self.timeStep, on: .main, in: .common).autoconnect().sink {_ in
            // print("UPDATING THE SM!")
            self.update()
        }
        
    }
    
    func stop() {
        // print("STOPPING THE TIMER!")
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
        // print("\t \(secondsRemaining) seconds left in ROUND \(roundCount + 1)/\(nRounds)")
        secondsRemaining -= timeStep
        
        if secondsRemaining <= 0 {
            // print("\tROUND \(roundCount + 1)/\(nRounds) HAS ENDED")
            step()
        }
        
        
    }

    func step() {
        if self.state != .notset {
            Task {
                // print("[\(self.state)] UPLOADING \(self.dataToUpload) ...")
                await self.upload()
                
                Task { @MainActor in
                    if (self.roundCount + 1) >= self.nRounds {
                        self.stop()
                        return
                    }
                }
                
                await self.download()
                
                // print("[\(self.state)] DOWNLOADED \(self.downloadedData) ...")
                
                Task { @MainActor in
                    // print("SWITCHING ROUNDS: \(self.roundCount) --> \(self.roundCount + 1)")
                    self.roundCount += 1
                }
                
            }
        }

        
        switch self.state {
            case.notset:
                // print("NS --> IP w/ \(self.downloadedData) / \(self.dataToUpload)")

                self.state = .initialPrompt
                self.stateContent = AnyView(InitialPromptView(stateMachine: self))
            case .initialPrompt:
                // print("IP --> DFP w/ \(self.downloadedData) / \(self.dataToUpload)")

                self.state = .drawFromPrompt
                self.stateContent =  AnyView(DrawFromPromptView(stateMachine: self))
            case .drawFromPrompt:
                // print("DFP --> PFD w/ \(self.downloadedData) / \(self.dataToUpload)")

                self.state = .promptFromDrawing
                self.stateContent = AnyView(PromptFromDrawingView(stateMachine: self))
            case .promptFromDrawing :
                // print("PFD --> DFP w/ \(self.downloadedData) / \(self.dataToUpload)")

                self.state = .drawFromPrompt
                self.stateContent = AnyView(DrawFromPromptView(stateMachine: self))
        }
        
        secondsRemaining = self.roundDurations[self.state, default: defaultRoundDuration]
    }
}
