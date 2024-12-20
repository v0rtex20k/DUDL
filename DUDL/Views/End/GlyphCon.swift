//
//  GlyphCon.swift
//  DUDL
//
//  Created by V on 12/20/24.
//

import Foundation
import SwiftUI

struct GlyphCon: UIViewRepresentable {
    var nGlyphs: Int
    var gidx: Int
    
    func makeUIView(context: Context) -> UIPageControl {
        let control = UIPageControl()
        control.numberOfPages = nGlyphs
        control.currentPage = gidx
        control.backgroundStyle = .prominent
        control.allowsContinuousInteraction = false
        
        return control
    }
    
    func updateUIView(_ uiView: UIPageControl, context: Context) {
        uiView.numberOfPages = nGlyphs
        uiView.currentPage = gidx
    }
}
