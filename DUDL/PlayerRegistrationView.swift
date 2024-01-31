//
//  PlayerRegistrationView.swift
//  DUDL
//
//  Created by V on 1/30/24.
//

import Foundation
import Combine
import SwiftUI

struct PlayerRegistrationView : View {
    @Binding var currentView: String
    @Binding var restController: RestController
    
    let maxLen = 15
    
    @State var nickname: String = ""
    
    func limitText(_ upper: Int) {
        if nickname.count > upper {
            nickname = String(nickname.prefix(upper))
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                VStack {
                    TextField("Username", text: $nickname)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(width: 300, height: 200)
                        .font(Font.custom("Galvji", size: 16))
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.gradient)
                            .frame(width: 250, height: 250, alignment: .center)
                            .shadow(radius: 3)
                        )
                        .disableAutocorrection(true)
                        .onReceive(Just(nickname)) { _ in limitText(maxLen) }
                        .onSubmit {
                            print("Got username \(nickname)")
                        }
                    Spacer()
                    ColorPickerView()
                }
            }
        }
    }
}

#Preview {
   struct PreviewWrapper: View {
       @State var rc: RestController = RestController(host: "127.0.0.1", port:8001)
       var body: some View {
           PlayerRegistrationView(currentView: .constant("PlayerRegistrationView"), restController: $rc)
       }
   }
   return PreviewWrapper()
}

