//
//  RestController.swift
//  DUDL
//
//  Created by V on 1/29/24.
//

import Foundation
import UIKit

struct RestController {
    var _host: String
    var _port: Int
    var _maxRetryCount: Int
    var _retryTimeout: TimeInterval
    
    let oneSecondInNanoseconds = TimeInterval(1_000_000_000)
    
    enum RequestType {
        case GET
        case POST
        case DELETE
        // add more as needed
    }
    
    init(host: String = "127.0.0.1", port: Int = 8001, maxRetryCount: Int = 1, retryTimeout: TimeInterval = 3) {
        self._host = host
        self._port = port
        self._maxRetryCount = maxRetryCount
        self._retryTimeout = retryTimeout
    }
    
    func start_new_game(completionHandler: @escaping (Result<NewGameCodeRequest, HTTPError>) -> Void) async {
        let rid: String = await UIDevice.current.identifierForVendor!.uuidString
        if rid.isEmpty {
            return completionHandler(.failure(.unidentifiedUser))
        }
        let new_game_request = NewGameCodeRequest(requester_id: rid)
        guard let uploadData = try? JSONEncoder().encode(new_game_request) else {
            print("Cannot start a game w/ null Requester Id")
            return completionHandler(.failure(.unidentifiedUser))
        }
        
        return await post_async(endpoint: "start-new-game", uploadData: uploadData, completionHandler: completionHandler)
    }
    
    func get_async(endpoint: String, completionHandler: @escaping (Result<NewGameCodeRequest, HTTPError>) -> Void) async {
        return await self._perform_request(endpoint: endpoint, type: .GET, uploadData: nil, completionHandler: completionHandler)
    }
    
    func post_async(endpoint: String, uploadData: Data, completionHandler: @escaping (Result<NewGameCodeRequest, HTTPError>) -> Void) async {
        return await self._perform_request(endpoint: endpoint, type: .POST, uploadData: uploadData, completionHandler: completionHandler)
    }
    
    func _perform_request(endpoint: String, type: RequestType, uploadData: Data?, completionHandler: @escaping (Result<NewGameCodeRequest, HTTPError>) -> Void) async {
        
        var status_code: Int = 0
        
        let url_str = "http://\(self._host):\(self._port)/\(endpoint)"
        let url = URL(string: url_str)
        
        for _ in 0..<self._maxRetryCount {
            do {
                switch type {
                    case .POST:
                        print("POST-ing to \(url_str) ...")
                        var request = URLRequest(url: url!)
                        request.httpMethod = "POST"
                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                        guard uploadData != nil else {
                            completionHandler(.failure(.invalidRequest))
                            return
                        }
                        
                        let (responseData, response) = try await URLSession.shared.upload(
                            for: request,
                            from: uploadData!
                        )
                        
                        if let httpResponse = response as? HTTPURLResponse {
                            status_code = httpResponse.statusCode
                        }
                    
                        let decoded_result = try JSONDecoder().decode(NewGameCodeRequest.self, from: responseData)
                        
                        completionHandler(.success(decoded_result))
                        return
                        
                    case .GET:
                        print("GET-ing from \(url_str) ...")
                        let (responseData, response) = try await URLSession.shared.data(from: url!)
                        
                        guard let httpResponse = response as? HTTPURLResponse else {
                            completionHandler(.failure(.invalidResponse))
                            return
                        }
                    
                        status_code = httpResponse.statusCode
                        
                        let decoded_result = try JSONDecoder().decode(NewGameCodeRequest.self, from: responseData)
                        
                        completionHandler(.success(decoded_result))
                        return
                    default:
                        print("Unable to handle \"\(url_str)\" request ...")
                        completionHandler(.failure(.invalidRequest))
                        return
                }
                
            } catch {
                let timeout = UInt64(oneSecondInNanoseconds * self._retryTimeout)
                try! await Task<Never, Never>.sleep(nanoseconds: timeout)
                continue  // try again
            }
        }
        
        switch status_code {
            case 0:
                completionHandler(.failure(.unidentifiedUser))
            case 200..<300:
                completionHandler(.failure(.invalidResponse))
            case 300..<500:
                completionHandler(.failure(.invalidRequest))
            case 500...:
                completionHandler(.failure(.serviceUnavailable))
            default:
                completionHandler(.failure(.unknown))
        }
        return
    }
    
}
