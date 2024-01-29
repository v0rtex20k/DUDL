//
//  HomeView.swift
//  DUDL
//
//  Created by Victor on 1/28/24.
//

import SwiftUI
    

struct HomeView: View {
    @State private var shouldDraw = false
    @Binding var currentView: String
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
                        .font(.caption)
                        .foregroundStyle(.white)
                        .onAppear {
                            withAnimation(.easeIn(duration: 4).delay(0.5).repeatForever(autoreverses:true)){
                                shouldDraw.toggle()
                            }
                        }
                    Text("DÜDL")
                        .padding()
                        .font(Font.custom("Galvji-Bold", size: 25))
                        .foregroundStyle(.white)
                    Spacer()
                    HStack {
                        Spacer()
                        Button("Start"){
                            self.currentView = "StartView"
                        }
                            .padding()
                            .foregroundStyle(.white)
                            .font(Font.custom("Galvji", size: 18))
                            .background(
                                RoundedRectangle(cornerRadius: 10).stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                    .foregroundStyle(.white)
                                    .frame(width: geo.size.width / 4,
                                                  height: geo.size.height / 15)
                            )
                        Spacer()
                        Button("Join"){
                            self.currentView = "JoinView"
                        }
                            .padding()
                            .font(Font.custom("Galvji", size: 18))
                            .foregroundStyle(.white)
                            .background(
                                RoundedRectangle(cornerRadius: 10).stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                    .foregroundStyle(.white)
                                    .frame(width: geo.size.width / 4,
                                                  height: geo.size.height / 15)
                            )
                        Spacer()
                    }
                    Spacer()
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    HomeView(currentView: .constant("HomeView"))
}

