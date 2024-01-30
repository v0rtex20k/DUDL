//
//  WebStructs.swift
//  DUDL
//
//  Created by Victor on 1/28/24.
//

import Foundation

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

// MARK: Player Info

struct Player: Decodable {
    let player_id: String
    let nickname: String
    let turnIndex: Int
}
