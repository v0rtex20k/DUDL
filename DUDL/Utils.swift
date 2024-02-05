//
//  Utils.swift
//  DUDL
//
//  Created by V on 2/4/24.
//

import Foundation

func limitText(text: String, _ limit: Int) {
    if text.count > limit {
        text = String(text.prefix(limit))
    }
}

