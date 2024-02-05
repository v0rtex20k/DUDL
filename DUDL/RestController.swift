//
//  RestController.swift
//  DUDL
//
//  Created by V on 1/29/24.
//

import Foundation
import UIKit
import SwiftUI

struct FailableDecodable<Base : Decodable> : Decodable {

    let base: Base?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.base = try? container.decode(Base.self)
    }
}

struct RestController {
    var _host: String
    var _port: Int
    var _maxRetryCount: Int
    var _retryDelay: TimeInterval
    var _requestTimeout: TimeInterval
    
    let oneSecondInNanoseconds = TimeInterval(1_000_000_000)
    
    enum RequestType {
        case GET
        case POST
        case DELETE
        // add more as needed
    }
    
    init(host: String = "192.168.1.7", port: Int = 8001, maxRetryCount: Int = 1, retryDelay: TimeInterval = 5, requestTimeout: TimeInterval = 10) {
        self._host = host
        self._port = port
        self._maxRetryCount = maxRetryCount
        self._retryDelay = retryDelay
        self._requestTimeout = requestTimeout
    }
    
    mutating func update_host(host: String) {
        if !host.isEmpty {
            self._host = host
        }
    }
    
    // MARK: Encodings
    
    func encodeNewGameRequest() async -> Optional<Data> {
        let pid: String = await UIDevice.current.identifierForVendor!.uuidString
        if pid.isEmpty {
            return nil
        }
        let req = NewGameRequest(playerId: pid)
        guard let uploadData = try? JSONEncoder().encode(req) else {
            return nil
        }
        return uploadData
    }
    
    func encodeJoinGameRequest(code: String) async -> Optional<Data> {
        let pid: String = await UIDevice.current.identifierForVendor!.uuidString
        if pid.isEmpty {
            return nil
        }
        let req = JoinGameRequest(gameCode: code, playerId: pid)
        guard let uploadData = try? JSONEncoder().encode(req) else {
            return nil
        }
        return uploadData
    }
    
    func encodeUpdatePlayerProfileRequest(code: String, nickname: String, rgba: RGBA) async -> Optional<Data> {
        let pid: String = await UIDevice.current.identifierForVendor!.uuidString
        if pid.isEmpty {
            return nil
        }
        
        let req = PlayerProfile(gameCode: code, playerId: pid, nickname: nickname, rgba: rgba)
        guard let uploadData = try? JSONEncoder().encode(req) else {
            return nil
        }
        return uploadData
    }
    
    func encodeAllPlayerProfilesRequest(code: String) async -> Optional<Data> {
        let pid: String = await UIDevice.current.identifierForVendor!.uuidString
        if pid.isEmpty {
            return nil
        }
        let req = AllPlayerProfilesRequest(gameCode: code)
        guard let uploadData = try? JSONEncoder().encode(req) else {
            return nil
        }
        return uploadData
    }
    
    
    
    // MARK: Use Cases
    
    func startNewGame(completionHandler: @escaping (Result<NewGameResponse, HTTPError>) -> Void) async {
        guard let uploadData = await self.encodeNewGameRequest() else {
            completionHandler(.failure(.unidentifiedUser))
            return
        }
            
        return await postAsync(endpoint: "start-game", uploadData: uploadData) { post_result in
            do {
                switch post_result {
                    case .success(let post_data):
                        let decoded_result = try JSONDecoder().decode(NewGameResponse.self, from: post_data)
                        
                        completionHandler(.success(decoded_result))
                        return
                        
                    case .failure(let http_error):
                        completionHandler(.failure(http_error))
                }
            }
            catch {
                print("Failed to decode NewGameResponse")
                completionHandler(.failure(.decodingError))
            }
            
        }
    }
    
    func joinExistingGame(_ code: String, completionHandler: @escaping (Result<JoinGameResponse, HTTPError>) -> Void) async {
        guard let uploadData = await self.encodeJoinGameRequest(code: code) else {
            completionHandler(.failure(.unidentifiedUser))
            return
        }
        
        return await postAsync(endpoint: "join-game", uploadData: uploadData) { post_result in
            do {
                switch post_result {
                    case .success(let post_data):
                        let decoded_result = try JSONDecoder().decode(JoinGameResponse.self, from: post_data)
                        
                        completionHandler(.success(decoded_result))
                        return
                        
                    case .failure(let http_error):
                        completionHandler(.failure(http_error))
                }
            }
            catch {
                
                print("Failed to decode JoinGameResponse")
//                do {
//                    try print(String(decoding: post_result.get(), as: UTF8.self))
//                } catch {
//                    print("nope ;)")
//                }
                completionHandler(.failure(.decodingError))
            }
            
        }
        
    }
    
    func updatePlayerProfile(code: String, nickname: String, rgba: RGBA, completionHandler: @escaping (Result<UpdatePlayerProfileResponse, HTTPError>) -> Void) async {
        guard let uploadData = await self.encodeUpdatePlayerProfileRequest(code: code, nickname: nickname, rgba: rgba) else {
            completionHandler(.failure(.unidentifiedUser))
            return
        }
        
        return await postAsync(endpoint: "update-player-profile", uploadData: uploadData) { post_result in
            do {
                switch post_result {
                    case .success(let post_data):
                        let decoded_result = try JSONDecoder().decode(UpdatePlayerProfileResponse.self, from: post_data)
                        
                        completionHandler(.success(decoded_result))
                        return
                        
                    case .failure(let http_error):
                        completionHandler(.failure(http_error))
                }
            }
            catch {
                
                print("Failed to decode UpdatePlayerProfileResponse")
//                do {
//                    try print(String(decoding: post_result.get(), as: UTF8.self))
//                } catch {
//                    print("nope ;)")
//                }
                completionHandler(.failure(.decodingError))
            }
            
        }
        
    }
    
    func allPlayerProfiles(code: String, completionHandler: @escaping (Result<[PlayerProfile], HTTPError>) -> Void) async {
        guard let uploadData = await self.encodeAllPlayerProfilesRequest(code: code) else {
            completionHandler(.failure(.unidentifiedUser))
            return
        }
        
        return await postAsync(endpoint: "get-all-active-player-profiles", uploadData: uploadData) { post_result in
            do {
                switch post_result {
                    case .success(let post_data):
                    
                        dump(post_data)
                    
                        let decoded_result = try JSONDecoder()
                                                    .decode([FailableDecodable<PlayerProfile>].self, from: post_data)
                                                    .compactMap { $0.base }
                        
                        if decoded_result.isEmpty {
                            completionHandler(.failure(.decodingError))
                        }
                    
                        completionHandler(.success(decoded_result))
                        return
                        
                    case .failure(let http_error):
                        completionHandler(.failure(http_error))
                }
            }
            catch {
                
                print("Failed to decode list of PlayerProfiles")
//                do {
//                    try print(String(decoding: post_result.get(), as: UTF8.self))
//                } catch {
//                    print("nope ;)")
//                }
                completionHandler(.failure(.decodingError))
            }
            
        }
    }
    
        
    // MARK: Core Functionality

    func getAsync(endpoint: String, completionHandler: @escaping (Result<Data, HTTPError>) -> Void) async {
        return await self._performRequest(endpoint: endpoint, type: .GET, uploadData: nil, completionHandler: completionHandler)
    }
    
    func postAsync(endpoint: String, uploadData: Data, completionHandler: @escaping (Result<Data, HTTPError>) -> Void) async {
        return await self._performRequest(endpoint: endpoint, type: .POST, uploadData: uploadData, completionHandler: completionHandler)
    }

    func _performRequest(endpoint: String, type: RequestType, uploadData: Data?, completionHandler: @escaping (Result<Data, HTTPError>) -> Void) async {
            
            var status_code: Int = 0
            
            let url_str = "http://\(self._host):\(self._port)/\(endpoint)"
            let url = URL(string: url_str)
            
            for _ in 0..<self._maxRetryCount {
                do {
                    switch type {
                        case .POST:
                            print("POST-ing to \(url_str) ...")
                        var request = URLRequest(url: url!,
                                                 cachePolicy: .useProtocolCachePolicy,
                                                 timeoutInterval: self._requestTimeout)
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
                            
                            completionHandler(.success(responseData))
                            return
                            
                        case .GET:
                            print("GET-ing from \(url_str) ...")
                            let (responseData, response) = try await URLSession.shared.data(from: url!)
                            
                            guard let httpResponse = response as? HTTPURLResponse else {
                                completionHandler(.failure(.invalidResponse))
                                return
                            }
                        
                            status_code = httpResponse.statusCode
                            
                            completionHandler(.success(responseData))
                            return
                        default:
                            print("Unable to handle \"\(url_str)\" request ...")
                            completionHandler(.failure(.invalidRequest))
                            return
                    }
                    
                } catch {
                    let timeout = UInt64(oneSecondInNanoseconds * self._retryDelay)
                    try? await Task<Never, Never>.sleep(nanoseconds: timeout)
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
