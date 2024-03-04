//
//  DrawingUtils.swift
//  DUDL
//
//  Created by V on 3/4/24.
//

import Foundation
import PencilKit


extension PKDrawing {
    /// Convert your drawing to a base64-encoded String
    func base64EncodedString() -> String {
        return dataRepresentation().base64EncodedString()
    }
    
    enum DecodingError: Error {
        case decodingError
    }
    
    init(base64Encoded base64: String) throws {
        guard let data = Data(base64Encoded: base64) else {
            throw DecodingError.decodingError
        }
        try self.init(data: data)
    }
}
