//
//  DraggableZStack.swift
//  DUDL
//
//  Created by V on 2/6/24.
//

import Foundation
import SwiftUI

protocol BDZSContainerView: View {
    associatedtype Content
    init(currentView: Binding<ViewFinder>, dragToView: ViewFinder, content: @escaping () -> Content)
}

struct BlackDraggableZStack<Content: View>: BDZSContainerView {
    @Binding var currentView: ViewFinder
    var dragToView: ViewFinder
    var content: () -> Content

    var body: some View {
        ZStack{
            Color.black.edgesIgnoringSafeArea(.all)
            content()
        }
        .gesture(DragGesture(minimumDistance: 20, coordinateSpace: .global)
            .onEnded { value in
                let h = value.translation.width
                let v = value.translation.height
                
                if abs(h) > abs(v) {
                    currentView = .home
                    let impactMed = UIImpactFeedbackGenerator(style: .medium)
                    impactMed.impactOccurred()
                }
            }
        )
        .onTapGesture(count: 1) {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
        }
    }
}
