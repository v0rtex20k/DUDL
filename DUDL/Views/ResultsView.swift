//
//  ResultsView.swift
//  DUDL
//
//  Created by V on 2/10/24.
//

import SwiftUI

struct ResultsView: View {
    @State private var alertMessage: String = ""
    @State private var shouldShowAlert: Bool = false
    @State private var shouldShowContent: Bool = true
    let alertTitle = "Unable to Join Game"
    
    private let maxLen = 50 // just to prevent some type of crazy long string
    
    @Binding var gameCode: String
    @Binding var currentView: ViewFinder
    @Binding var restController: RestController
    
    
    var body: some View {
        BlackDraggableZStack(currentView: $currentView, dragToView: .profile, onDragEndFunc: nil) {
            Text("RESULTS")
                .foregroundStyle(Color(primary_color))
                .font(Font.custom("Galvji", size: 16))
        }
    }
}

//#Preview {
//    ResultsView()
//}
