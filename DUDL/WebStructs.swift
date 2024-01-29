//
//  WebStructs.swift
//  DUDL
//
//  Created by Victor on 1/28/24.
//

import Foundation


struct Game: Decodable {
    let id: String
    let players: [Player]
}
        
struct Player: Decodable {
    let id: String
    let name: String
    let turn_index: Int
}
