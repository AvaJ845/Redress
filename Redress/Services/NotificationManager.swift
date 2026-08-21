import Foundation
import UserNotifications

enum NotificationManager {
    static func scheduleDeadlineReminder(for claim: Claim, settlement: Settlement) {
        guard let triggerDate = Calendar.current.date(byAdding: .day, value: -3, to: settlement.claimDeadline),
              triggerDate > Date() else { return }

        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                schedule(for: claim, settlement: settlement, triggerDate: triggerDate)
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    guard granted else { return }
                    schedule(for: claim, settlement: settlement, triggerDate: triggerDate)
                }
            case .denied, .ephemeral:
                break
            @unknown default:
                break
            }
        }
    }

    private static func schedule(for claim: Claim, settlement: Settlement, triggerDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Claim deadline approaching"
        content.body = "\(settlement.title) closes soon — file before \(settlement.claimDeadline.formatted(date: .abbreviated, time: .omitted))."
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "deadline-\(claim.id.uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelReminder(for claim: Claim) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["deadline-\(claim.id.uuidString)"])
    }
}
