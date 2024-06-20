//
//  End.swift
//  DUDL
//
//  Created by V on 5/12/24.
//

import Foundation
import SwiftUI


struct EndView : View {
    @Binding var gameCode: String
    @Binding var currentView: ViewFinder
    @Binding var restController: RestController
    
    @State private var alertMessage: String = ""
    @State private var shouldShowAlert: Bool = false
    @State private var shouldShowContent: Bool = true
    
    @State private var submissions: [PlayerSubmission] = [
        PlayerSubmission(playerProfile: PlayerProfile(gameCode: "happy-hippo", playerId: "123", nickname: "ghost", rgba: RGBA(r: 100, g: 0, b: 100, a: 1)), content: "hello")
    ]
    @State var currentIndex: Int = 0
    
    func getAllSubmissions() async {
        await restController.getAllSubmissions(gameCode) { result in
            switch result {
            case .success(let subs):
                submissions = subs
                shouldShowContent = false
            case .failure(let error):
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
    
    var body: some View {
        
        VStack(spacing: 0){
            
            HStack{
                
                Button {
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.bold())
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                        
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.white.opacity(0.6),lineWidth: 1)
                        )
                }

                
                Spacer()
                
                Button {
                    
                } label: {
                    Text("Skip")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }

            }
            .overlay(
            
                // Custom Paging Indicator...
                HStack(spacing: 5){
                 
                    ForEach(submissions.indices,id: \.self){index in
                        Capsule()
                            .fill(Color.white.opacity(currentIndex == index ? 1 : 0.55))
                            .frame(width: currentIndex == index ? 18 : 4, height: 4)
                            .animation(.easeInOut, value: currentIndex)
                    }
                }
            )
            .padding()
            
            // ScrollView for adapting for small screens..
            ScrollView(getRect().height < 750 ? .vertical : .init(), showsIndicators: false) {
                
                VStack(spacing: 20){
                    
                    Text("Prepare Training")
                        .fontWeight(.bold)
                        .foregroundColor(Color.white.opacity(0.6))
                        .padding(.top,20)
                    
                    Text("Let's create a\ntraining plan\nfor you!")
                        .font(.system(size: 38, weight: .bold))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .foregroundColor(.white)
                    
                    // Carousel SLider....
   
                    InfiniteCarouselView(submissions: $submissions, currentIndex: $currentIndex)
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
            
            // Bottom Bar..
            
            HStack{
                
                Text("Next Step")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.body.bold())
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                        
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.white.opacity(0.3),lineWidth: 1)
                        )
                }
            }
            .padding(.top,25)
            .padding(.horizontal,30)
            .padding(.bottom,12)
            .background(
            
                Color.black
                    .clipShape(CustomCorner(corners: [.topLeft,.topRight], radius: 38))
                    .ignoresSafeArea()
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
        
            // Gradient BG...
            LinearGradient(colors: [
                Color.green,
                Color.white
            ], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea(.keyboard)
        )
        .ignoresSafeArea(.keyboard)
        .task {
            await getAllSubmissions()
        }
    }
}


#Preview {
   struct PreviewWrapper: View {
       @State var rc: RestController = RestController(host: "127.0.0.1", port:8001)
       @State var vf: ViewFinder = .end
       var body: some View {
           EndView(gameCode: .constant("chunky-rottweiler"), currentView: $vf, restController: $rc)
       }
   }
   return PreviewWrapper()
}


