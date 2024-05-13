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

struct StateMachine {
    @Binding var stateContent: AnyView
    
    
    var gameCode: String = ""
    var nRounds: Int = 0
    var roundCount: Int = 0
    var timer: AnyCancellable? = nil
    var roundDuration: TimeInterval = 0
    var timeStep: TimeInterval = 0
    var secondsElapsed: TimeInterval = 0
    var restController: RestController? = nil
    
    private var isDone: Bool = false
    
    @State private var state: GameState = .notset
    @State var downloadData: String = ""
    @State var uploadData: String = ""
    
    
    @State private var alertMessage: String = ""
    @State private var shouldShowAlert: Bool = false
    @State private var shouldShowContent: Bool = true
    let alertTitle = "Unable to Submit Your Work"



}
