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
    case decodingError
    case serviceUnavailable
    case unidentifiedUser
    case unknown
    case emptyResponse
    // TODO: add more
}

