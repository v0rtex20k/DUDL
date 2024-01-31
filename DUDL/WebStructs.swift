//
//  WebStructs.swift
//  DUDL
//
//  Created by Victor on 1/28/24.
//

import Foundation
import SwiftUI

// MARK: Starting a New Game

struct NewGameRequest: Encodable {
    let playerId: String
}

struct NewGameResponse: Decodable {
    let gameCode: String
}


// MARK: Joining an Existing Game
        
struct JoinGameRequest: Encodable {
    let gameCode: String
    let playerId: String
}

struct JoinGameResponse: Decodable {
    let playerId: String
}

// MARK: Updating Player Profile

struct RGBA : Encodable {
    let r: Float
    let g: Float
    let b: Float
    let a: Float
}

struct UpdatePlayerProfileRequest: Encodable {
    // NOTE: server must enforce that players can only join one game at a time
    let playerId: String
    let nickname: String
    let rgba: RGBA
}

struct UpdatePlayerProfileResponse: Decodable {
    let playerId: String
}
