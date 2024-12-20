//
//  End.swift
//  DUDL
//
//  Created by V on 5/12/24.
//

import Foundation
import SwiftUI
import PencilKit


extension PKDrawing {
    mutating func scale(w: CGFloat, h: CGFloat) {
        var scaleFactor: CGFloat = 0
        
        if self.bounds.width != w {
            scaleFactor = w / self.bounds.width
        } else if self.bounds.height != h {
            scaleFactor = h / self.bounds.height
        }
        
        let transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        
        self.transform(using: transform)
    }
}

struct EndView : View {
    @Binding var gameCode: String
    @Binding var currentView: ViewFinder
    @Binding var restController: RestController
    
    @State private var alertMessage: String = ""
    @State private var shouldShowAlert: Bool = false
    @State private var shouldShowContent: Bool = true
    
    @State private var currGlyphID: String = ""
    @State var glyphs: [Glyph] = []
    
    func debug() async {
        await self.restController.debug(code: self.gameCode) { result in
            switch result {
                case .success:
                    // print("DEBUG MODE ACTIVATED")
                    break
                case .failure(let error):
                    switch error {
                        case .serviceUnavailable:
                            self.alertMessage = "Failed to connect to server \n Please check your internet connection"
                        default:
                            self.alertMessage = "Something went wrong \n Please try again later"
                    }
                    self.shouldShowAlert = true
                    print(error.localizedDescription)
            }
        }
    }
    
    
    func getAllSubmissions() async {
        await restController.getGlyphs(gameCode) { result in
            switch result {
            case .success(let gs):
                glyphs = gs
                // print("GOT GLYPHS: \(gs)")
            case .failure(let error):
                // print("FAILURE")
                switch error {
                case .serviceUnavailable:
                    alertMessage = "Failed to connect to server \n Please check your internet connection"
                default:
                    alertMessage = "Something went wrong \n Please try again later"
                }
                shouldShowAlert = true
                print(error.localizedDescription)
            }
        }
    }
    
    struct PKCanvasRepresentation: UIViewRepresentable {
        var drawing: PKDrawing

        func makeUIView(context: Context) -> PKCanvasView {
            let canvasView = PKCanvasView()
            canvasView.drawing = drawing
            canvasView.isUserInteractionEnabled = false // disable user interaction
            canvasView.backgroundColor = .clear
            return canvasView
        }

        func updateUIView(_ uiView: PKCanvasView, context: Context) {
            uiView.drawing = drawing
        }
    }
    
    struct CanvasView: View {
        var drawing: PKDrawing

        var body: some View {
            PKCanvasRepresentation(drawing: drawing)
        }
    }
    
    
    func buildResultView(w: CGFloat, h: CGFloat, content: String?) -> some View {
        if content == nil {
            return AnyView(
                VStack{
                    Text("\(Image(systemName: "x.circle"))")
                        .opacity(0.6)
                        .foregroundStyle(Color.black)
                        .font(Font.custom("Galvji", size: 56))
                        .padding()
                    Text("Content not found")
                        .opacity(0.6)
                        .foregroundStyle(Color.black)
                        .font(Font.custom("Galvji", size: 16))
                }
                
            )
        }
        else {
            if let data = Data(base64Encoded: content!),
               var drawing = try? PKDrawing(data: data) {
                drawing.scale(w: w, h: h)
                return AnyView(
                    CanvasView(drawing: drawing)
                        .padding()
                )
            } else {
                return AnyView(
                    Text(content!)
                        .foregroundStyle(Color.black)
                        .font(Font.custom("Galvji", size: 26))
                        .padding()
                )
            }
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            Color.black.edgesIgnoringSafeArea(.all)
            VStack {
                Button(action: {
                    Task.detached {
                        await getAllSubmissions()
                    }
                }, label: {
                    Text("\(gameCode)")
                        .padding()
                        .foregroundStyle(Color(primary_color))
                        .font(Font.custom("Galvji", size: 26))
                })
                TabView(selection: $currGlyphID) {
                    ForEach(glyphs) { glyph in
                        let _ = print(glyphs)
                        VStack {
                            Spacer()
                            Spacer()
                            Capsule(style: .continuous)
                                .fill(glyph.creator.rgba.color)
                                .frame(width: geo.size.width * 0.5, height: geo.size.width * 0.1)
                                .padding()
                                .overlay {
                                    Text(glyph.creator.nickname)
                                        .padding()
                                        .font(Font.custom("Galvji", size: 18))
                                }
                            Spacer()
                            RoundedRectangle(cornerRadius: 25, style: .continuous)
                                .opacity(0.5)
                                .padding()
                                .frame(width: geo.size.width * 0.85, height:  geo.size.height * 0.6)
                                .tag(glyph.id.uuidString)
                                .overlay(
                                    RoundedRectangleWithGrid(cornerRadius: 25)
                                )
                                .overlay (
                                    buildResultView(w: geo.size.width * 0.5, h: geo.size.height * 0.6, content: glyph.content)
                                        
                                )
                            Spacer()
                            Spacer()
                            Spacer()
                        }
                    }
                }
                .onChange(of: currGlyphID) {
                    Task.detached {
                        await getAllSubmissions()
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .overlay(alignment: .bottom) {
                    GlyphCon(nGlyphs: glyphs.count, gidx: originalIndex(currGlyphID))
                        .offset(y: -15)
                }
            }
        }
        .task {
            await getAllSubmissions()
        }
        .overlay(alignment: .bottomTrailing) {
            Button("", systemImage: "house.circle.fill"){
                self.gameCode = ""
                self.currentView = .home
            }
            .padding()
            .font(Font.custom("Galvji", size: 32))
            .foregroundStyle(Color(primary_color))
        }
    }
    
    func glyphIndex(_ g: Glyph) -> Int {
        return glyphs.firstIndex(of: g) ?? 0
    }
    
    func originalIndex(_ id: String) -> Int {
        return glyphs.firstIndex { page in
            page.id.uuidString == id
        } ?? 0
    }
}


#Preview {
   struct PreviewWrapper: View {
       @State var rc: RestController = RestController(host: "127.0.0.1", port:8001)
       @State var vf: ViewFinder = .end
       var body: some View {
           let ev = EndView(gameCode: .constant("chunky-rottweiler"), currentView: $vf, restController: $rc)
           ev.task {
               await ev.debug()
           }
       }
   }
   return PreviewWrapper()
}

extension View{
    func getRect()->CGRect{
        return UIScreen.main.bounds
    }
}

