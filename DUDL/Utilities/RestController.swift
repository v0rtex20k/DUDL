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
    
    init(host: String = "192.168.1.7", port: Int = 8001, maxRetryCount: Int = 3, retryDelay: TimeInterval = 1, requestTimeout: TimeInterval = 5) {
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
    
    func deviceId() async -> String {
        return await UIDevice.current.identifierForVendor!.uuidString
    }
    
    func encodeRequest<T : Encodable>(_ request: T) async -> Optional<Data> {
        guard let uploadData = try? JSONEncoder().encode(request) else {
            return nil
        }
        return uploadData
    }
    
    // MARK: Encodings
    
    func encodeRemovePlayerRequest(code: String, playerId: String) async -> Optional<Data> {
        let req = RemovePlayerRequest(gameCode: code, playerId: playerId)
        guard let uploadData = try? JSONEncoder().encode(req) else {
            return nil
        }
        return uploadData
    }
    
    
    
    // MARK: Use Cases
    
    func createGame(completionHandler: @escaping (Result<NewGameResponse, HTTPError>) -> Void) async {
        guard let uploadData = await self.encodeRequest(NewGameRequest(playerId: await deviceId())) else {
            completionHandler(.failure(.unidentifiedUser))
            return
        }
            
        return await postAsync(endpoint: "create-game", uploadData: uploadData) { post_result in
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
        guard let uploadData = await self.encodeRequest(JoinGameRequest(gameCode: code, playerId: await deviceId())) else {
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
        guard let uploadData = await self.encodeRequest(PlayerProfile(gameCode: code, 
                                                                      playerId: await deviceId(),
                                                                      nickname: nickname, rgba: rgba)) else {
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
        guard let uploadData = await self.encodeRequest(AllPlayerProfilesRequest(gameCode: code)) else {
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
    
    func removePlayer(code: String, playerId: Optional<String> = nil, completionHandler: @escaping (Result<Data, HTTPError>) -> Void) async {
        
        var pid: String = ""

        if playerId != nil {
            pid = playerId!
        } else {
            pid = await deviceId()
        }
        
        guard let uploadData = await self.encodeRequest(RemovePlayerRequest(gameCode: code, playerId: pid)) else {
            completionHandler(.failure(.unidentifiedUser))
            return
        }
        
        return await postAsync(endpoint: "remove-player", uploadData: uploadData) { post_result in
            switch post_result {
                case .success(let post_data):
                    // doesn't really return anything
                    completionHandler(.success(post_data))
                case .failure(let http_error):
                    completionHandler(.failure(http_error))
            }
        }
    }
    
    func gameStatus(code: String, completionHandler: @escaping (Result<GameStatusResponse, HTTPError>) -> Void) async {
        guard let uploadData = await self.encodeRequest(GameStatusRequest(gameCode: code)) else {
            completionHandler(.failure(.unidentifiedUser))
            return
        }
        
        return await postAsync(endpoint: "game-status", uploadData: uploadData) { post_result in
            do {
                switch post_result {
                    case .success(let post_data):
                        dump(post_data)
                        let decoded_result = try JSONDecoder().decode(GameStatusResponse.self, from: post_data)
                        
                        completionHandler(.success(decoded_result))
                        
                    case .failure(let http_error):
                        completionHandler(.failure(http_error))
                }
            }
            catch {
                
                print("Failed to decode GameStatusResponse")
                completionHandler(.failure(.decodingError))
            }
            
        }
    }
    
    func startGame(code: String, completionHandler: @escaping (Result<Bool, HTTPError>) -> Void) async {
        guard let uploadData = await self.encodeRequest(StartGameRequest(gameCode: code)) else {
            completionHandler(.failure(.unidentifiedUser))
            return
        }

        return await postAsync(endpoint: "start-game", uploadData: uploadData) { post_result in
            switch post_result {
                case .success:
                    print("Sucessfully processed StartGame Response!")
                    completionHandler(.success(true))
                    
                case .failure(let http_error):
                    print("Failed to process StartGame Response!")
                    completionHandler(.failure(http_error))
            }
        }

    }
    
    func debug(code: String, completionHandler: @escaping (Result<Bool, HTTPError>) -> Void) async {
        guard let uploadData = await self.encodeRequest(DebugContentRequest(gameCode: code, playerId: await deviceId())) else {
            completionHandler(.failure(.unidentifiedUser))
            return
        }

        return await postAsync(endpoint: "debug", uploadData: uploadData) { post_result in
            switch post_result {
                case .success:
                    print("Sucessfully processed Debug Response!")
                    completionHandler(.success(true))
                    
                case .failure(let http_error):
                    print("Failed to process Debug Response!")
                    completionHandler(.failure(http_error))
            }
        }
    }
    
    func uploadContent(code: String, data: String, roundIndex: Int, completionHandler: @escaping (Result<Bool, HTTPError>) -> Void) async {
        print("UPLOADING ROUND \(roundIndex + 1) CONTENT \"\(data)\" to Game \(code) ...")
        guard let uploadData = await self.encodeRequest(UploadContentRequest(gameCode: code, playerId: await deviceId(), content: data, roundIdx: roundIndex)) else {
            completionHandler(.failure(.unidentifiedUser))
            return
        }

        return await postAsync(endpoint: "upload-content", uploadData: uploadData) { post_result in
            switch post_result {
                case .success:
                    print("Sucessfully posted UploadContent")
                    completionHandler(.success(true))
                    
                case .failure(let http_error):
                    print("Failed to post UploadContent")
                    completionHandler(.failure(http_error))
            }
        }
    }
    
    func downloadContent(code: String, roundIndex: Int, completionHandler: @escaping (Result<String, HTTPError>) -> Void) async {
        guard let uploadData = await self.encodeRequest(DownloadContentRequest(gameCode: code, playerId: await deviceId(), roundIdx: roundIndex)) else {
            completionHandler(.failure(.unidentifiedUser))
            return
        }

        return await postAsync(endpoint: "download-content", uploadData: uploadData) { post_result in
            do {
                switch post_result {
                    case .success(let post_data):
                        let decoded_result = try JSONDecoder().decode(DownloadContentResponse.self, from: post_data)
                        
                        completionHandler(.success(decoded_result.content))
                        print("Sucessfully pulled DownloadContentResponse!")
                        print("DOWNLOADED ROUND \(roundIndex + 1) CONTENT \(decoded_result.content) from Game \(code) ...")
                        
                    case .failure(let http_error):
                        print("Failed to process DownloadContentResponse!")
                        completionHandler(.failure(http_error))
                }
            } catch {
                print("Failed to decode DownloadContentResponse")
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

    func _performRequest(endpoint: String, type: RequestType, uploadData: Data?, failOnEmpty: Bool = false, completionHandler: @escaping (Result<Data, HTTPError>) -> Void) async {
            
            var status_code: Int = 0
            var returnedData: Data = Data()
            
            let url_str = "http://\(self._host):\(self._port)/\(endpoint)"
            let url = URL(string: url_str)
            
            retryLoop : for _ in 0..<self._maxRetryCount {
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
                        
                            returnedData = responseData
                            
                            if 200..<300 ~= status_code {
                                break retryLoop // if you've got something, run w/ it
                            }
                            
                        case .GET:
                            print("GET-ing from \(url_str) ...")
                            let (responseData, response) = try await URLSession.shared.data(from: url!)
                        
                            returnedData = responseData
                            
                            guard let httpResponse = response as? HTTPURLResponse else {
                                completionHandler(.failure(.invalidResponse))
                                return
                            }
                        
                            status_code = httpResponse.statusCode
                            
                            if 200..<300 ~= status_code {
                                break retryLoop // if you've got something, run w/ it
                            }
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
                    completionHandler(failOnEmpty && status_code == 204 ? .failure(.emptyResponse) : .success(returnedData))
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
