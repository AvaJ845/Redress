import SwiftUI
import SwiftData

@main
struct RedressApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Settlement.self, Claim.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    @State private var subscriptions = SubscriptionManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(subscriptions)
        }
        .modelContainer(sharedModelContainer)
    }
}
