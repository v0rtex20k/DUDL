//
//  WebStructs.swift
//  DUDL
//
//  Created by Victor on 1/28/24.
//

import Foundation

struct NewGameCodeResponse: Decodable {
    let code: String
}
        
struct Player: Decodable {
    let id: String
    let nickname: String
    let turn_index: Int
}

struct NewGameCodeRequest: Encodable {
    let id: String
}
