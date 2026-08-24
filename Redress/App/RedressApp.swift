import SwiftUI
import SwiftData

@main
struct RedressApp: App {
    var sharedModelContainer: ModelContainer = RedressApp.makeModelContainer()

    /// A store-open failure (corrupted file, disk full, a future
    /// non-lightweight migration) must never hard-crash the app at every
    /// future launch with no recovery path but reinstalling — `try!` did
    /// exactly that. If the on-disk store won't open, the store file is
    /// unrecoverable anyway, so the only real recovery is starting fresh;
    /// only if that also fails does this fall back to in-memory, which
    /// keeps the app usable for the session instead of crashing outright.
    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([Settlement.self, Claim.self, WatchlistCase.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        if let container = try? ModelContainer(for: schema, configurations: [configuration]) {
            return container
        }

        if let storeURL = configuration.url as URL?, FileManager.default.fileExists(atPath: storeURL.path) {
            try? FileManager.default.removeItem(at: storeURL)
            if let container = try? ModelContainer(for: schema, configurations: [configuration]) {
                return container
            }
        }

        let fallbackConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        guard let fallback = try? ModelContainer(for: schema, configurations: [fallbackConfiguration]) else {
            fatalError("Redress could not create even an in-memory ModelContainer — the schema itself is invalid.")
        }
        return fallback
    }

    @State private var subscriptions = SubscriptionManager()
    @AppStorage("redress.appearance") private var appearance: AppAppearance = .system

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(subscriptions)
                .preferredColorScheme(appearance.colorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}
