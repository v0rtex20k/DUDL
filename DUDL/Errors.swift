//
//  Errors.swift
//  DUDL
//
//  Created by V on 1/29/24.
//

import Foundation

enum HTTPError: Error {
    case invalidRequest
    case invalidResponse
    case serviceUnavailable
    case unidentifiedUser
    case unknown
    // TODO: add more
}

