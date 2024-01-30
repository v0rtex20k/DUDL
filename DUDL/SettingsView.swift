//
//  SettingsView.swift
//  DUDL
//
//  Created by V on 1/29/24.
//

import Foundation
import SwiftUI

func isValidIP(_ s: String) -> Bool {
    guard !s.isEmpty else {
        return false
    }
    
    let pattern_2 = "(25[0-5]|2[0-4]\\d|1\\d{2}|\\d{1,2})\\.(25[0-5]|2[0-4]\\d|1\\d{2}|\\d{1,2})\\.(25[0-5]|2[0-4]\\d|1\\d{2}|\\d{1,2})\\.(25[0-5]|2[0-4]\\d|1\\d{2}|\\d{1,2})"
    let regexText_2 = NSPredicate(format: "SELF MATCHES %@", pattern_2)
    let result_2 = regexText_2.evaluate(with: s)
    return result_2
}

enum HostUpdateStatus {
    case unchanged
    case updatedFailed
    case updatedSuceeded
}

struct SettingsView : View {
    @State var host: String = ""
    @State var status: HostUpdateStatus = .unchanged
    @Binding var currentView: String
    @Binding var restController: RestController
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                VStack {
                    Spacer()
                    Text("Host IP Address")
                        .foregroundStyle(.white)
                        .font(Font.custom("Galvji", size: 16))
                    TextField(restController._host, text: $host)
                        .disableAutocorrection(true)
                        .onSubmit {
                                if isValidIP(host) {
                                    print("Updated RC.host to \(host)")
                                    restController.update_host(host: host)
                                    status = .updatedSuceeded
                                    Task {
                                        try! await Task.sleep(nanoseconds: 3_000_000_000)
                                        status = .unchanged
                                    }
                                } else {
                                    status = .updatedFailed
                                    print("Ignoring invalid host \(host)")
                                }
                    }
                        .foregroundStyle(status == .updatedSuceeded ? .green : (status == .updatedFailed ? .red : .black))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .multilineTextAlignment(.center)
                    .frame(width: geo.size.width * 0.80)
                    .font(Font.custom("Galvji", size: 20))
                    Spacer()
                }
            }.onTapGesture(count: 2) {
                currentView = "HomeView"
                let impactMed = UIImpactFeedbackGenerator(style: .medium)
                impactMed.impactOccurred()
            }
        }
    }
}

#Preview {
   struct PreviewWrapper: View {
       @State var rc: RestController = RestController(host: "127.0.0.1", port:8001)
       var body: some View {
           SettingsView(currentView: .constant("SettingsView"), restController: $rc)
       }
   }
   return PreviewWrapper()
}
