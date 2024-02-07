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

// MARK: Player Profiles

struct RGBA : Encodable, Decodable, Equatable, Hashable {
    let r: Float
    let g: Float
    let b: Float
    let a: Float
    
    static func == (lhs: RGBA, rhs: RGBA) -> Bool {
        return  lhs.r == rhs.r &&
                lhs.g == rhs.g &&
                lhs.b == rhs.b &&
                lhs.a == rhs.a
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(r)
        hasher.combine(g)
        hasher.combine(b)
        hasher.combine(a)
    }
}

struct PlayerProfile: Encodable, Decodable, Equatable, Hashable {
    // NOTE: server must enforce that players can only join one game at a time,
    // keyed by the gameCode they previously entered
    let gameCode: String?
    let playerId: String
    let nickname: String
    let rgba: RGBA
    
    init(gameCode: String, playerId: String, nickname: String, rgba: RGBA) {
        self.gameCode = gameCode
        self.playerId = playerId
        self.nickname = nickname
        self.rgba = rgba
    }
    
    static func == (lhs: PlayerProfile, rhs: PlayerProfile) -> Bool {
        return  lhs.playerId == rhs.playerId &&
                lhs.nickname == rhs.nickname &&
                lhs.rgba == rhs.rgba
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(playerId)
        hasher.combine(nickname)
        hasher.combine(rgba)
    }
}

struct UpdatePlayerProfileResponse: Decodable {
    let playerId: String
}

struct AllPlayerProfilesRequest: Encodable {
    let gameCode: String
}

// MARK: Eject a player from a game

struct EjectPlayerRequest: Encodable {
    let gameCode: String
    let playerId: String
}

struct EjectPlayerResponse: Decodable {
    let playerId: String
}
