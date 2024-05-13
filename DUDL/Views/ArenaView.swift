//
//  ArenaView.swift
//  DUDL
//
//  Created by V on 2/10/24.
//

import SwiftUI
import Combine

enum GameState {
    case notset, initialPrompt, drawFromPrompt, promptFromDrawing
}


struct ArenaView: View {
    @Binding var gameCode: String
    @Binding var nRounds: Int
    @Binding var currentView: ViewFinder
    @Binding var restController: RestController
    
    @State var state: GameState = .notset
    @State var content: AnyView = AnyView(EmptyView())
    
    @State var downloadData: String = ""
    @State var uploadData: String = ""
    
    @State var isGameComplete: Bool = false
    @State var secondsElapsed: TimeInterval = 0
    @State var secondsRemaining: TimeInterval = 0
    @State var roundCount: Int = 0
    @State var alertMessage: String = ""
    @State var shouldShowAlert: Bool = false
    @State var shouldShowContent: Bool = true

    let alertTitle = "Unable to Join Game"
    let timeStep: TimeInterval = 0.5
    let roundDuration: TimeInterval = 5
    
    
    // MARK: timeStep = 0.5 seconds
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    func debug() async {
        await restController.debug(code: gameCode) { result in
            switch result {
                case .success:
                    print("DEBUG MODE ACTIVATED")
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

    
    func stop() {
        print("STOPPING THE TIMER!")
        timer.upstream.connect().cancel()
        isGameComplete = true
        currentView = .end
    }
    
    func download() async {
        await restController.downloadContent(code: gameCode, roundIndex: roundCount) { result in
            switch result {
                case .success(let content):
                    downloadData = content
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
    
    func upload() async {
        await restController.uploadContent(code: gameCode, data: uploadData, roundIndex: roundCount) { result in
            switch result {
            case .success:
                return
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

        if state != .notset {
            // print("[\(state)] UPLOADING \(uploadData) ...")
            
            Task {
                await upload()
                uploadData.removeAll()
            } // UPload what YOU did this round
            
            if (roundCount + 1) >= nRounds {
                stop()
                return
            }
            
            Task {
                downloadData.removeAll()
                await download()
            }  // DOWNload what your friend did this round
            
            // print("[\(state)] DOWNLOADED \(downloadData) ...")
            
            print("SWITCHING ROUNDS: \(roundCount) --> \(roundCount + 1)")
            roundCount += 1
        }

        
        switch state {
            case.notset:
                print("NS --> IP")

                state = .initialPrompt
                content = AnyView(InitialPromptView(prompt: $uploadData, secondsRemaining: $secondsRemaining))
            case .initialPrompt:
                print("IP --> DFP w/ (\(downloadData), \(uploadData))")

                state = .drawFromPrompt
                content =  AnyView(DrawFromPromptView(prompt: $downloadData, drawing: $uploadData, secondsRemaining: $secondsRemaining))
            case .drawFromPrompt:
                print("DFP --> PFD w/ (\(downloadData), \(uploadData))")

                state = .promptFromDrawing
                content = AnyView(PromptFromDrawingView(prompt: $downloadData, drawing: $uploadData, secondsRemaining: $secondsRemaining))
            case .promptFromDrawing :
                print("PFD --> DFP w/ (\(downloadData), \(uploadData)")

                state = .drawFromPrompt
                content = AnyView(DrawFromPromptView(prompt: $downloadData, drawing: $uploadData, secondsRemaining: $secondsRemaining))
        }
    }
    
    var body: some View {
        
        ZStack {
            Color.black.ignoresSafeArea(edges: .all)
            VStack {
                Spacer()
                content
            }
            Spacer()
            Spacer()
        }
        .onAppear {
            step()
        }
        .onChange(of: secondsElapsed) {
            secondsRemaining = roundDuration - secondsElapsed
        }
        .onReceive(timer) { _ in
            update()
        }
        .onDisappear {
            stop()
        }
    }
}


#Preview {
   struct PreviewWrapper: View {
       @State var rc: RestController = RestController(host: "192.168.1.10", port:8001)
       @State var vf: ViewFinder = .arena
       
       var body: some View {
           EmptyView()
           let ar = ArenaView(gameCode: .constant("happy-hippo"), nRounds: .constant(3), currentView: $vf, restController: $rc)
           ar.onAppear {
               Task.detached {
                   await ar.debug()
               }
           }
       }
   }
   return PreviewWrapper()
}
