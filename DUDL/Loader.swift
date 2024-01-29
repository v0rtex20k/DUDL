//
//  Loader.swift
//  DUDL
//
//  Created by V on 1/29/24.
//

import Foundation
import SwiftUI

struct Loader: View {
    @State private var progress = 0.6

    var body: some View {
        VStack {
            ProgressView(value: progress)
                .progressViewStyle(.circular)
        }
    }
}
