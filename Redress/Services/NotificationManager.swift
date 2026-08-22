import Foundation
import UserNotifications

enum NotificationManager {
    /// Always cancels any existing reminder for this claim before deciding
    /// whether to schedule a new one. This makes the function safe to call
    /// again for an already-scheduled claim — e.g. when a settlement's
    /// deadline is corrected after a claim already exists — instead of
    /// leaving a stale reminder pointing at a deadline that's no longer
    /// real. Without this, a deadline moved earlier (so the new trigger
    /// date is already in the past) would hit the early-return below and
    /// leave the old, now-wrong reminder in place indefinitely.
    static func scheduleDeadlineReminder(for claim: Claim, settlement: Settlement) {
        cancelReminder(for: claim)

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
