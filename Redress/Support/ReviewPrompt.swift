import Foundation

/// Momentum (ASO): ask for a review only at a *happy moment* — a claim
/// actually getting paid — and at most once per app version. Never at
/// launch, never mid-task.
enum ReviewPrompt {
    private static let promptedVersionKey = "redress.reviewPromptedVersion"

    static func shouldRequestAfterPaidClaim(defaults: UserDefaults = .standard) -> Bool {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        guard defaults.string(forKey: promptedVersionKey) != version else { return false }
        defaults.set(version, forKey: promptedVersionKey)
        return true
    }
}
