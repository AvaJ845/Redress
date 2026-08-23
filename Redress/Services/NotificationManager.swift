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

    /// The on-device-only version of "notify me about new opportunities":
    /// no personalization, no server, no relevance model — just "the
    /// catalog genuinely grew since last time you had the app open."
    /// Never called for the very first-ever seed load (SettlementCatalog
    /// gates that), so this only fires for settlements added by a real
    /// update after the user already has the app.
    static func notifyNewSettlements(_ settlements: [Settlement]) {
        guard !settlements.isEmpty else { return }

        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                scheduleNewSettlementsNotification(settlements)
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    guard granted else { return }
                    scheduleNewSettlementsNotification(settlements)
                }
            case .denied, .ephemeral:
                break
            @unknown default:
                break
            }
        }
    }

    private static func scheduleNewSettlementsNotification(_ settlements: [Settlement]) {
        let content = UNMutableNotificationContent()
        if settlements.count == 1, let only = settlements.first {
            content.title = "New settlement found"
            content.body = "\(only.title) is now open — check if you qualify."
        } else {
            content.title = "\(settlements.count) new settlements found"
            content.body = "Redress found new open settlements — check if you qualify."
        }
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "new-settlements-\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }
}
