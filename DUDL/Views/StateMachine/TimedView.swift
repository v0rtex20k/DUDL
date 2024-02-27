//
//  TimedView.swift
//  DUDL
//
//  Created by V on 2/26/24.
//

import SwiftUI

protocol TimedContainerView: View {
    associatedtype Content
    @inlinable init(timeLeft: Float, @ViewBuilder content: @escaping () -> Content)
}

struct TimedView<Content: View>: TimedContainerView {
    var timeLeft: Float
    var content: () -> Content
    private var startDate: Date = Date.now
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        content()
        .onReceive(timer) { firedDate in
            timeLeft = Int(firedDate.timeIntervalSince(startDate)) // seconds
            print("\t \(timeLeft) seconds left in ROUND")
            if timeLeft == 0 {
                print("\t ROUND IS OVER")
                stateMachine?.step()
                timeLeft = 60
            }
        }
    }
}
