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
    @inlinable init(currentView: Binding<ViewFinder>, gameCode: Binding<String>, shouldShowAlert: Binding<Bool>, alertTitle: String, alertMessage: String, shouldShowContent: Binding<Bool>, contentValue: Binding<String>, @ViewBuilder content: @escaping (Binding<String>) -> Content)
}

struct RestfulGroup<Content: View>: RGContainerView {
    @Binding var currentView: ViewFinder
    @Binding var gameCode: String
    @Binding var shouldShowAlert: Bool
    var alertTitle: String
    var alertMessage: String
    @Binding var shouldShowContent: Bool
    @Binding var contentValue: String
    var content: (Binding<String>) -> Content
    
    var body: some View {
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
            content(contentValue.isEmpty ? $gameCode :  $contentValue)
        }   else {
                ProgressView {
                    Text("Connecting to Server")
                        .foregroundStyle(Color(primary_color))
                        .font(Font.custom("Galvji", size: 20))
                        .foregroundStyle(Color(primary_color))
                }
                .padding()
                .progressViewStyle(.circular)
                .tint(Color(primary_color))
    
        }
    }
}

