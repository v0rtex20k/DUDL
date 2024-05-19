//
//  InitialPromptState.swift
//  DUDL
//
//  Created by V on 2/18/24.
//

import SwiftUI
import Combine

struct InitialPromptView: View {
    private let maxLen = 50 // just to prevent some type of crazy long string
    
    @ObservedObject var stateMachine : StateMachine
    

    func limitText() {
        print("LIMITING TEXT: \(stateMachine.dataToUpload.count) vs \(maxLen)")
        stateMachine.dataToUpload = stateMachine.dataToUpload.replacingOccurrences(of: "[^\\S ]+", with: "", options: .regularExpression)
        if stateMachine.dataToUpload.count > maxLen {
            stateMachine.dataToUpload = String(stateMachine.dataToUpload.prefix(maxLen))
        }
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    VStack {
                        Spacer()
                        Text("Say something funny")
                            .padding()
                            .border(Color.green)
                            .foregroundStyle(Color(primary_color))
                            .font(Font.custom("Galvji", size: 18))
                        TextField("something-funny", text: $stateMachine.dataToUpload, axis: .vertical)
                            .lineLimit(5)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .onChange(of: stateMachine.dataToUpload) {
                                limitText()
                            }
                            .foregroundStyle(.black)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .multilineTextAlignment(.center)
                            .frame(width: 0.8 * geo.size.width)
                            .fixedSize(horizontal: false, vertical: true)
                            .font(Font.custom("Galvji", size: 24))
                        Text("\(stateMachine.dataToUpload.count) / \(maxLen)")
                            .padding()
                            .foregroundStyle(Color(primary_color))
                            .font(Font.custom("Galvji", size: 16))
                        Spacer()
                        Spacer()
                    }
                }
            }
            .ignoresSafeArea(.keyboard)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    VStack {
                        Text("\(Int(ceil(stateMachine.secondsRemaining)))")
                            .font(.subheadline)
                            .foregroundStyle(Color(primary_color))
                    }
                }
            }
            .toolbarBackground(.hidden, for: .automatic)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
}

#Preview {
    InitialPromptView(stateMachine: StateMachine())
}
