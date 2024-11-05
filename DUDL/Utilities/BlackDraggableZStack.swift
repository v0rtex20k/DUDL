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
    @inlinable init(currentView: Binding<ViewFinder>, dragToView: Optional<ViewFinder>, enableOneTap: Bool, onDragEndFunc: Optional<() async -> Void>, @ViewBuilder content: @escaping () -> Content)
}

struct BlackDraggableZStack<Content: View>: BDZSContainerView {
    @Binding var currentView: ViewFinder
    var dragToView: Optional<ViewFinder> = nil
    var enableOneTap: Bool = true
    var onDragEndFunc: Optional<() async -> Void>
    var content: () -> Content
    
    // MARK: VIEW CREATION

    var body: some View {
        ZStack{
            Color.black.edgesIgnoringSafeArea(.all)
            content()
        }
        .ignoresSafeArea(.keyboard)
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .global)
            .onEnded { value in
                let h = value.translation.width
                let v = value.translation.height
                
                if abs(h) > abs(v) {

                    if let onDragEndFunc = onDragEndFunc {
                        Task {
                            await onDragEndFunc()
                        }
                    }
                    if let dtv = dragToView {
                        currentView = dtv
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    }
                    
                }
            }
        )
        .onTapGesture(count: 1) {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
