//
//  WebStructs.swift
//  DUDL
//
//  Created by Victor on 1/28/24.
//

import Foundation

struct NewGameCodeRequest: Codable {
    let requester_id: String
}

struct NewGameCodeResponse: Decodable {
    let code: String
}
        
struct Player: Decodable {
    let id: String
    let nickname: String
    let turn_index: Int
}
