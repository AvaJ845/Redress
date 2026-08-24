import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(\.modelContext) private var context
    @Query private var claims: [Claim]
    @State private var showingPaywall = false
    @State private var showingDeleteConfirmation = false
    @AppStorage("redress.appearance") private var appearance: AppAppearance = .system

    private var totalRecovered: Double {
        claims.filter { $0.status == .paid }.compactMap(\.actualPayout).reduce(0, +)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Subscription") {
                    HStack {
                        Text("Redress Plus")
                        Spacer()
                        Label(
                            subscriptions.isPlus ? "Active" : "Not subscribed",
                            systemImage: subscriptions.isPlus ? "checkmark.seal.fill" : "circle"
                        )
                        .font(.subheadline)
                        .foregroundStyle(subscriptions.isPlus ? .green : .secondary)
                    }
                    if !subscriptions.isPlus {
                        Button("Upgrade to Plus") { showingPaywall = true }
                    }
                    Button("Restore Purchases") {
                        Task { await subscriptions.restore() }
                    }
                }

                if SubscriptionManager.isRunningInTestFlight {
                    Section {
                        Toggle(
                            "Force Redress Plus",
                            isOn: Binding(
                                get: { subscriptions.debugForcePlusEnabled },
                                set: { subscriptions.debugForcePlusEnabled = $0 }
                            )
                        )
                    } header: {
                        Text("TestFlight Testing")
                    } footer: {
                        Text("Only visible in TestFlight builds — never appears in the App Store release. Lets testers exercise Redress Plus features without a real purchase.")
                    }
                }

                if subscriptions.isPlus {
                    Section("Value guarantee") {
                        Text("You've recovered \(totalRecovered, format: .currency(code: "USD")) so far via claims marked paid.")
                        if let price = subscriptions.product?.price, Decimal(totalRecovered) < price {
                            Text("That's less than this year's subscription cost. Redress can't issue refunds directly — only Apple can — but you're entitled to ask.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Link(destination: URL(string: "https://reportaproblem.apple.com")!) {
                                Label("Request a refund from Apple", systemImage: "arrow.up.right.square")
                            }
                        }
                    }
                }

                Section {
                    Picker(selection: $appearance) {
                        ForEach(AppAppearance.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    } label: {
                        Label("Appearance", systemImage: "circle.lefthalf.filled")
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("System follows your iPhone's Light/Dark setting. Light or Dark override it just for Redress.")
                }

                Section("Privacy") {
                    Text(AppLegal.privacyPolicySummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Your data") {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete all claims & documents", systemImage: "trash")
                    }
                }

                Section("About") {
                    Text("Redress is not a law firm and does not provide legal advice. It never files a claim on your behalf — every submission happens on the official administrator's site.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPaywall) {
                PaywallView(reason: "Track unlimited claims and unlock the document vault.")
            }
            .confirmationDialog(
                "Delete all claims and documents? This can't be undone.",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Everything", role: .destructive, action: deleteAllData)
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func deleteAllData() {
        for claim in claims {
            DocumentVault.deleteAll(for: claim.documentFileNames)
            NotificationManager.cancelReminder(for: claim)
            context.delete(claim)
        }
        context.saveOrLog()
    }
}
