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
    
    let pattern = "(25[0-5]|2[0-4]\\d|1\\d{2}|\\d{1,2})\\.(25[0-5]|2[0-4]\\d|1\\d{2}|\\d{1,2})\\.(25[0-5]|2[0-4]\\d|1\\d{2}|\\d{1,2})\\.(25[0-5]|2[0-4]\\d|1\\d{2}|\\d{1,2})"
    let pred = NSPredicate(format: "SELF MATCHES %@", pattern)
    return pred.evaluate(with: s)
    
}

enum HostUpdateStatus {
    case unchanged
    case updateFailed
    case updateSuceeded
}

struct SettingsView : View {
    @State var host: String = ""
    @State var status: HostUpdateStatus = .unchanged
    @Binding var currentView: ViewFinder
    @Binding var restController: RestController
    var body: some View {
        GeometryReader { geo in
            BlackDraggableZStack(currentView: $currentView, dragToView: .home, content: {
                VStack {
                    Spacer()
                    Text("Host IP Address")
                        .foregroundStyle(.white)
                        .font(Font.custom("Galvji", size: 16))
                    TextField(restController._host, text: $host)
                        .keyboardType(.numberPad)
                        .disableAutocorrection(true)
                        .onSubmit {
                            if isValidIP(host) {
                                print("Updated RC.host to \(host)")
                                restController.update_host(host: host)
                                status = .updateSuceeded
                                Task {
                                    // aka 3 seconds
                                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                                    status = .unchanged
                                }
                            } else {
                                status = .updateFailed
                                print("Ignoring invalid host \(host)")
                            }
                        }
                        .foregroundStyle(status == .updateSuceeded ? .green : (status == .updateFailed ? .red : .black))
                        .multilineTextAlignment(.center)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: geo.size.width * 0.80)
                        .font(Font.custom("Galvji", size: 20))
                    Spacer()
                    Spacer()
                }
            })
            .ignoresSafeArea(.keyboard)
        }
    }
}

//#Preview {
//   struct PreviewWrapper: View {
//       @State var rc: RestController = RestController(host: "192.168.1.7", port:8001)
//       var body: some View {
//           SettingsView(currentView: .settings, restController: $rc)
//       }
//   }
//   return PreviewWrapper()
//}
