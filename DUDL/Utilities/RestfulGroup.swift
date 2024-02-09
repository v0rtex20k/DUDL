//
//  RestfulVStack.swift
//  DUDL
//
//  Created by V on 2/6/24.
//

import Foundation
import SwiftUI

protocol RGContainerView: View {
    associatedtype Content
    @inlinable init(currentView: Binding<ViewFinder>, gameCode: Binding<String>, shouldShowAlert: Binding<Bool>, alertTitle: String, alertMessage: String, shouldShowContent: Binding<Bool>, @ViewBuilder content: @escaping (Binding<String>) -> Content)
}

struct RestfulGroup<Content: View>: RGContainerView {
    @Binding var currentView: ViewFinder
    @Binding var gameCode: String
    @Binding var shouldShowAlert: Bool
    var alertTitle: String
    var alertMessage: String
    @Binding var shouldShowContent: Bool
    var content: (Binding<String>) -> Content
    
    var body: some View {
        Group {
            if shouldShowAlert {
                Text("")
                    .alert(alertTitle, isPresented: $shouldShowAlert) {
                        Button("OK", role: .cancel) {
                            gameCode.removeAll()
                            currentView = .home
                        }
                    } message: {
                        Text(alertMessage)
                    }
            } 
            else if shouldShowContent {
                content($gameCode)
            }   else {
                    ProgressView {
                        Text("Connecting to Server")
                            .foregroundStyle(Color(primary_color))
                            .padding()
                            .font(Font.custom("Galvji", size: 20))
                            .foregroundStyle(Color(primary_color))
                    }
                    .progressViewStyle(.circular)
                    .tint(Color(primary_color))
        
            }
        }

    }
}

