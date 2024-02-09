//
//  HomeView.swift
//  DUDL
//
//  Created by Victor on 1/28/24.
//

import SwiftUI
    

struct HomeView: View {
    @State var shouldDraw = false
    @Binding var currentView: ViewFinder
    
    @State private var animationStateId = UUID()
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                VStack {
                    Spacer()
                    Scribble()
                        .trim(from: shouldDraw ? 0 : 1, to: 1)
                        .stroke(style:StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: geo.size.width / 2, height: geo.size.height / 3)
                        .foregroundColor(Color(primary_color))
                        .task {
                            withAnimation(.easeIn(duration: 4).delay(0.5).repeatForever(autoreverses:true)){
                                shouldDraw.toggle()
                            }
                        }
                        .id(animationStateId)
                    Text("DÜDL")
                        .padding()
                        .font(Font.custom("Galvji-Bold", size: 25))
                        .foregroundStyle(Color(primary_color))
                    Spacer()
                    HStack {
                        Spacer()
                        Button("Start"){
                            self.currentView = .start
                        }
                            .padding()
                            .foregroundStyle(Color(primary_color))
                            .font(Font.custom("Galvji", size: 18))
                            .background(
                                RoundedRectangle(cornerRadius: 10).stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                    .foregroundColor(Color(primary_color))
                                    .frame(width: geo.size.width / 4,
                                                  height: geo.size.height / 12)
                            )
                        Spacer()
                        Button("Join"){
                            self.currentView = .join
                        }
                        .padding()
                        .font(Font.custom("Galvji", size: 18))
                        .foregroundStyle(Color(primary_color))
                        .background(
                            RoundedRectangle(cornerRadius: 10).stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .foregroundColor(Color(primary_color))
                                .frame(width: geo.size.width / 4,
                                              height: geo.size.height / 12)
                        )
                        Spacer()
                    }
                    Spacer()
                    Spacer()
                    HStack{
                        Button("Settings", systemImage: "gearshape.2"){
                            self.currentView = .settings
                        }
                        .padding()
                        .font(Font.custom("Galvji", size: 12))
                        .foregroundStyle(Color(primary_color))

                    }
                }
            }
        }
    }
}

#Preview {
    ZStack{
        @State var vf: ViewFinder = .home
        HomeView(currentView: $vf)
    }
}

