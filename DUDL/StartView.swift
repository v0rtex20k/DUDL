//
//  StartView.swift
//  DUDL
//
//  Created by Victor on 1/28/24.
//

// When starting a game, all you need is a game code

import Foundation
import SwiftUI


func start_game(host: String = "127.0.0.1",
                port: Int = 8001,
                maxRetryCount: Int = 10,
                retryDelay: TimeInterval = 3,
                completionHandler: @escaping (Result<Game, HTTPError>) -> Void
) async {
    
    var status_code: Int = 0
    
    let url_str = "http://\(host):\(port)"
    let url = URL(string: url_str)
    
    for _ in 0..<maxRetryCount {
        print("Querying " + url_str + " ...")
        do {
            let (data, response) = try await URLSession.shared.data(from: url!)
            
            if let httpResponse = response as? HTTPURLResponse {
                status_code = httpResponse.statusCode
            }
            
            let decoded_data = try JSONDecoder().decode(Game.self, from: data)
            
            completionHandler(.success(decoded_data))
            
        } catch {
            let oneSecondInNanoseconds = TimeInterval(1_000_000_000)
            let delay = UInt64(oneSecondInNanoseconds * retryDelay)
            try! await Task<Never, Never>.sleep(nanoseconds: delay)
            continue  // try again
        }
    }
    
    switch status_code {
        case 200..<300:
            completionHandler(.failure(.invalidResponse))
        case 300..<500:
            completionHandler(.failure(.invalidRequest))
        case 500...:
            completionHandler(.failure(.serviceUnavailable))
        default:
            completionHandler(.failure(.unknown))
    }
}

struct StartView : View {
    @State var game: Game?
    @State private var shouldShowAlert: Bool = false
    @State private var alert_message: String = ""
    @Binding var currentView: String
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            Group {
                
                if shouldShowAlert {
                    Text("")
                    .alert("Unable to Start Game", isPresented: $shouldShowAlert) {
                            Button("OK", role: .cancel) {
                                    game = nil
                                    currentView = "HomeView"
                                }
                            } message: {
                                Text(alert_message)
                            }
                } else if let game_id = game?.id {
                    Text(game_id)
                        .foregroundStyle(.white)
                        .padding()
                        .font(Font.custom("Galvji", size: 30))
                        .foregroundStyle(.white)
                }   else {
                    ProgressView {
                        Text("Connecting to Server")
                            .foregroundStyle(.white)
                            .padding()
                            .font(Font.custom("Galvji", size: 20))
                            .foregroundStyle(.white)
                    }
                    .progressViewStyle(.circular)
                    .tint(.white)
                    
                }
            }
        }
        .task {
                await start_game() { result in
                    switch result {
                        case .success(let g):
                            game = g
                            print("Started a new game \(String(describing: game?.id))")
                        case .failure(let error):
                            switch error {
                                case .serviceUnavailable:
                                    alert_message = "Failed to connect to server \n Please check your internet connection"
                                default:
                                    alert_message = "Something went wrong \n Please try again later"
                            }
                            shouldShowAlert = true
                            print(error.localizedDescription)
                    }
                }
        }
    }
}

#Preview {
    StartView(game: nil, currentView: .constant("HomeView"))
}
