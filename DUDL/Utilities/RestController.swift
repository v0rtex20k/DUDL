//
//  RestController.swift
//  DUDL
//
//  Created by V on 1/29/24.
//

import Foundation
import UIKit
import SwiftUI

func str(_ data: Data) -> String? {
    return String(data: data, encoding: .utf8)
}

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
    
    init(host: String, port: Int, maxRetryCount: Int = 5, retryDelay: TimeInterval = 1, requestTimeout: TimeInterval = 5) {
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
            
        do {
            switch await postAsync(endpoint: "create-game", postData: uploadData) {
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
    
    func joinExistingGame(_ code: String, completionHandler: @escaping (Result<JoinGameResponse, HTTPError>) -> Void) async {
        guard let uploadData = await self.encodeRequest(JoinGameRequest(gameCode: code, playerId: await deviceId())) else {
            completionHandler(.failure(.unidentifiedUser))
            return
        }
        
        do {
            switch await postAsync(endpoint: "join-game", postData: uploadData) {
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
            completionHandler(.failure(.decodingError))
        }
        
    }
    
    func updatePlayerProfile(code: String, nickname: String, rgba: RGBA, completionHandler: @escaping (Result<UpdatePlayerProfileResponse, HTTPError>) -> Void) async {
        guard let uploadData = await self.encodeRequest(PlayerProfile(gameCode: code, 
                                                                      playerId: await deviceId(),
                                                                      nickname: nickname, rgba: rgba)) else {
            completionHandler(.failure(.unidentifiedUser))
            return
        }
        
        do {
            switch await postAsync(endpoint: "update-player-profile", postData: uploadData) {
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
            completionHandler(.failure(.decodingError))
        }
            
        
    }
    
    func allPlayerProfiles(code: String, completionHandler: @escaping (Result<[PlayerProfile], HTTPError>) -> Void) async {
        guard let uploadData = await self.encodeRequest(AllPlayerProfilesRequest(gameCode: code)) else {
            completionHandler(.failure(.unidentifiedUser))
            return
        }
        
        do {
            switch await postAsync(endpoint: "get-all-active-player-profiles", postData: uploadData) {
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
            completionHandler(.failure(.decodingError))
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
        
        switch await postAsync(endpoint: "remove-player", postData: uploadData) {
            case .success(let post_data):
                // doesn't really return anything
                completionHandler(.success(post_data))
            case .failure(let http_error):
                completionHandler(.failure(http_error))
        }
    }
    
    func gameStatus(code: String, completionHandler: @escaping (Result<GameStatusResponse, HTTPError>) -> Void) async {
        guard let uploadData = await self.encodeRequest(GameStatusRequest(gameCode: code)) else {
            completionHandler(.failure(.unidentifiedUser))
            return
        }
        
        do {
            switch await postAsync(endpoint: "game-status", postData: uploadData) {
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
    
    func startGame(code: String, completionHandler: @escaping (Result<Bool, HTTPError>) -> Void) async {
        guard let uploadData = await self.encodeRequest(StartGameRequest(gameCode: code)) else {
            completionHandler(.failure(.unidentifiedUser))
            return
        }

        switch await postAsync(endpoint: "start-game", postData: uploadData) {
            case .success:
                print("Sucessfully processed StartGame Response!")
                completionHandler(.success(true))
                
            case .failure(let http_error):
                print("Failed to process StartGame Response!")
                completionHandler(.failure(http_error))
        }

    }
    
    func debug(code: String, completionHandler: @escaping (Result<Bool, HTTPError>) -> Void) async {
        guard let uploadData = await self.encodeRequest(DebugContentRequest(gameCode: code, playerId: await deviceId())) else {
            completionHandler(.failure(.unidentifiedUser))
            return
        }

        switch await postAsync(endpoint: "debug", postData: uploadData) {
            case .success:
                print("Sucessfully processed Debug Response!")
                completionHandler(.success(true))
                
            case .failure(let http_error):
                print("Failed to process Debug Response!")
                completionHandler(.failure(http_error))
        }
    }
    
    func uploadContent(code: String, data: String, roundIndex: Int) async -> Result<Bool, HTTPError> {
        print("UPLOADING ROUND \(roundIndex + 1) CONTENT \"\(data)\" to Game \(code) ...")
        guard let uploadData = await self.encodeRequest(UploadContentRequest(gameCode: code, playerId: await deviceId(), content: data, roundIdx: roundIndex)) else {
            return .failure(.unidentifiedUser)
        }
            
        switch await postAsync(endpoint: "upload-content", postData: uploadData) {
            case .success:
                print("Sucessfully posted UploadContent")
                return .success(true)
                
            case .failure(let http_error):
                print("Failed to post UploadContent")
                return .failure(http_error)
        }
    }
    
    func downloadContent(code: String, roundIndex: Int) async -> Result<String, HTTPError> {
        guard let uploadData = await self.encodeRequest(DownloadContentRequest(gameCode: code, playerId: await deviceId(), roundIdx: roundIndex)) else {
            return .failure(.unidentifiedUser)
        }
        
        do {
            switch await postAsync(endpoint: "download-content", postData: uploadData, failOnEmpty: true) {
                case .success(let post_data):
                    let decoded_result = try JSONDecoder().decode(DownloadContentResponse.self, from: post_data)

                    print("Sucessfully pulled DownloadContentResponse!")
//                    print("DOWNLOADED ROUND \(roundIndex + 1) CONTENT \(decoded_result.content) from Game \(code) ...")
                    return .success(decoded_result.content)

                case .failure(let http_error):
                    print("Failed to process DownloadContentResponse!")
                    return .failure(http_error)
            }
        } catch {
            print("Failed to decode DownloadContentResponse \(error)")
            return .failure(.decodingError)
        }

    }
    
    func getPlayerCount(_ code: String, completionHandler: @escaping (Result<Int, HTTPError>) -> Void) async {
        guard let uploadData = await self.encodeRequest(PlayerCountRequest(gameCode: code)) else {
            completionHandler(.failure(.unidentifiedUser))
            return
        }
        
        do {
            switch await postAsync(endpoint: "get-player-count", postData: uploadData) {
                case .success(let post_data):
                    dump(post_data)
                    let decoded_result = try JSONDecoder().decode(PlayerCountResponse.self, from: post_data)
                    
                    completionHandler(.success(decoded_result.playerCount))
                    
                case .failure(let http_error):
                    completionHandler(.failure(http_error))
            }
        }
        catch {
            
            print("Failed to decode PlayerCountResponse")
            completionHandler(.failure(.decodingError))
        }
    }
    
    func getGlyphs(_ code: String, completionHandler: @escaping (Result<[Glyph], HTTPError>) -> Void) async {
        guard let uploadData = await self.encodeRequest(GetGlyphsRequest(gameCode: code, playerId: await deviceId())) else {
            completionHandler(.failure(.unidentifiedUser))
            return
        }
        
        do {
            switch await postAsync(endpoint: "load-results", postData: uploadData, failOnEmpty: true) {
                case .success(let post_data):
                
                retryLoop : for _ in 0..<self._maxRetryCount {
                    var playerCount = 0
                    let decoded_result = try JSONDecoder().decode([Glyph].self, from: post_data)
                    await getPlayerCount(code) { result in
                        switch result {
                        case .success(let c):
                            playerCount = c
                        case .failure(_):
                            break
                        }
                    }
                    if (decoded_result.count == playerCount) {
                        return completionHandler(.success(decoded_result))
                    }
                }
                    
                case .failure(let http_error):
                    print("Failed to process GetGlyphs!")
                    completionHandler(.failure(http_error))
            }
        }
        catch {
            print("Failed to decode GetGlyphsRequest: \(error)")
            completionHandler(.failure(.decodingError))
        }
        
    }
    // MARK: Core Functionality

    func getAsync(endpoint: String, failOnEmpty: Bool = false) async -> Result<Data, HTTPError> {
        return await self._performRequest(endpoint: endpoint, type: .GET, failOnEmpty: failOnEmpty)
    }
    
    func postAsync(endpoint: String, postData: Data, failOnEmpty: Bool = false) async -> Result<Data, HTTPError> {
        return await self._performRequest(endpoint: endpoint, type: .POST, data: postData, failOnEmpty: failOnEmpty)
    }

    func _performRequest(endpoint: String, type: RequestType, data: Data? = nil, failOnEmpty: Bool = false) async -> Result<Data, HTTPError> {
            
            var status_code: Int = 0
            var returnedData: Data = Data()
            
            let url_str = "http://\(self._host):\(self._port)/\(endpoint)"
            let url = URL(string: url_str)
            
            retryLoop : for _ in 0..<self._maxRetryCount {
                print("RETRYING \(type) Request @ \(endpoint) \(status_code) ...")
                do {
                    switch type {
                        case .POST:
                            print("POST-ing to \(url_str) ...")
                            var request = URLRequest(url: url!,
                                                 cachePolicy: .useProtocolCachePolicy,
                                                 timeoutInterval: self._requestTimeout)
                            request.httpMethod = "POST"
                            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                            guard data != nil else {
                                return .failure(.invalidRequest)
                            }
                            
                            let (responseData, response) = try await URLSession.shared.upload(
                                for: request,
                                from: data!
                            )
                            
                            if let httpResponse = response as? HTTPURLResponse {
                                status_code = httpResponse.statusCode
                            }
                        
                            returnedData = responseData
                            
                            if 200..<300 ~= status_code && !returnedData.isEmpty {
                                print("[\(endpoint)] POST RUNNING w/ \(String(describing: str(returnedData)))")
                                break retryLoop // if you've got something, run w/ it
                            }
                            
                        case .GET:
                            print("GET-ing from \(url_str) ...")
                            let (responseData, response) = try await URLSession.shared.data(from: url!)
                        
                            returnedData = responseData
                            
                            guard let httpResponse = response as? HTTPURLResponse else {
                                return .failure(.invalidResponse)
                            }
                        
                            status_code = httpResponse.statusCode
                            
                            if 200..<300 ~= status_code && !returnedData.isEmpty {
                                print("GET RUNNING w/ \(String(describing: str(returnedData)))")
                                break retryLoop // if you've got something, run w/ it
                            }
                        default:
                            print("Unable to handle \"\(url_str)\" request ...")
                            return .failure(.invalidRequest)
                    }
                    
                    let delay = UInt64(oneSecondInNanoseconds * self._retryDelay)
                    try? await Task<Never, Never>.sleep(nanoseconds: delay)
                    continue  // try again
                    
                } catch (let e) {
                    print("Failed to complete \(type) Request @ \(endpoint): \(e)")
                }
            }
            
            switch status_code {
                case 0:
                    return .failure(.unidentifiedUser)
                case 200..<300:
                    return ((failOnEmpty && (status_code == 204 || returnedData.isEmpty )) ? .failure(.emptyResponse) : .success(returnedData))
                case 300..<500:
                    return .failure(.invalidRequest)
                case 500...:
                    return .failure(.serviceUnavailable)
                default:
                    return .failure(.unknown)
            }
        }


}
