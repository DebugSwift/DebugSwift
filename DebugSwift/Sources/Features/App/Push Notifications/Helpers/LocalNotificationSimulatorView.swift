//
//  File.swift
//  
//
//  Created by Morgan Dock on 12/13/24.
//

import SwiftUI
import UserNotifications

@available(iOS 13.0, *)
struct LocalNotificationSimulatorView: View {
    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var textBody: String = ""
    @State private var badge: String = ""
    @State private var sound: Bool = true
    @State private var timeInterval: Double = 5

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Notification Content")) {
                    TextField("Title", text: $title)
                    TextField("Subtitle", text: $subtitle)
                    TextField("Body", text: $textBody)
                    TextField("Badge (number)", text: $badge)
                        .keyboardType(.numberPad)
                    Toggle("Play Sound", isOn: $sound)
                }

                Section(header: Text("Trigger")) {
                    HStack {
                        Text("Time Interval")
                        Spacer()
                        Text("\(Int(timeInterval)) seconds")
                    }
                    Slider(value: $timeInterval, in: 1...60, step: 1)
                }

                Section {
                    Button(action: scheduleNotification) {
                        Text("Schedule Notification")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationBarTitle("Notification Simulator")
        }
    }

    private func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.body = textBody
        if let badgeNumber = Int(badge) {
            content.badge = NSNumber(value: badgeNumber)
        }
        if sound {
            content.sound = .default
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    self.addNotification(request)
                }
            } else {
                print("Permission denied: \(error?.localizedDescription ?? "No error info")")
            }
        }

    }

    private func addNotification(_ request: UNNotificationRequest){
        UNUserNotificationCenter.current().add(request) { error in

            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Notification scheduled successfully!")
            }
        }
    }
}

@available(iOS 13.0, *)
struct LocalNotificationSimulatorView_Previews: PreviewProvider {
    static var previews: some View {
        LocalNotificationSimulatorView()
    }
}
