//
//  End.swift
//  DUDL
//
//  Created by V on 5/12/24.
//

import Foundation
import SwiftUI


struct EndView : View {
    var body: some View {
        ZStack{
            Color.black.edgesIgnoringSafeArea(.all)
            Text("This is the end ...")
                .font(.subheadline)
                .foregroundStyle(Color(primary_color))
        }
        .ignoresSafeArea(.keyboard)
    }
}
