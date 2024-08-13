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
    let existingPlayer: Bool
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
    
    var color: Color {
        return Color(UIColor(red: CGFloat(self.r), green: CGFloat(self.g), blue: CGFloat(self.b), alpha: CGFloat(self.a)))
    }
}

struct PlayerProfile: Encodable, Decodable, Equatable, Hashable {
    // NOTE: server must enforce that players can only join one game at a time,
    // keyed by the gameCode they previously entered
    let gameCode: String?
    let playerId: String
    let nickname: String
    let isHost: Bool?
    let rgba: RGBA
    
    
    init(gameCode: String?, playerId: String, nickname: String, rgba: RGBA, isHost: Bool? = false) {
        self.gameCode = gameCode
        self.playerId = playerId
        self.nickname = nickname
        self.rgba = rgba
        self.isHost = isHost
    }
    
    static func == (lhs: PlayerProfile, rhs: PlayerProfile) -> Bool {
        return lhs.playerId == rhs.playerId
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

// MARK: remove a player from a game

struct RemovePlayerRequest: Encodable {
    let gameCode: String
    let playerId: String
}

// MARK: start the game

struct GameStatusRequest: Encodable  {
    let gameCode: String
}

struct GameStatusResponse: Decodable  {
    let started: Bool
}

struct PlayerCountRequest: Encodable  {
    let gameCode: String
}

struct PlayerCountResponse: Decodable  {
    let playerCount: Int
}

struct StartGameRequest: Encodable  {
    let gameCode: String
}


// MARK: send game data
struct UploadContentRequest: Encodable  {
    let gameCode: String
    let playerId: String
    let content: String
    let roundIdx: Int
}

struct DownloadContentRequest: Encodable  {
    let gameCode: String
    let playerId: String
    let roundIdx: Int
}

struct DownloadContentResponse: Decodable  {
    let content: String
}

struct DebugContentRequest: Encodable  {
    let gameCode: String
    let playerId: String
}

// MARK: load final results

struct GetGlyphsRequest: Encodable {
    let gameCode: String
    let playerId: String
}

struct Glyph: Decodable, Equatable, Identifiable {
    var id = UUID()
    
    let content: String?
    let creator: PlayerProfile
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID() // Generate a new UUID if not present in JSON
        self.content = try container.decode(String.self, forKey: .content)
        self.creator = try container.decode(PlayerProfile.self, forKey: .creator)
    }
    
    private enum CodingKeys: String, CodingKey {
        case content
        case creator
    }
}
