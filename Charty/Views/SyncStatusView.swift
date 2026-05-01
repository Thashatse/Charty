import SwiftUI

struct SyncStatusView: View {
    @ObservedObject var service: AppleMusicService
    @ObservedObject var chartService: ChartService
    @StateObject private var cosmos = CosmosDBService()
    @Environment(\.dismiss) var dismiss
    
    private var lastSyncedText: String {
        formatted(date: service.lastSynced)
    }
    
    private var lastBuiltText: String {
        formatted(date: chartService.lastBuilt)
    }
    
    private func formatted(date: Date?) -> String {
        guard let date else { return "Never" }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        return f.localizedString(for: date, relativeTo: Date())
    }
    
    var body: some View {
        NavigationStack {
            List {
                
                // MARK: - Library Sync
                
                Section("Library Sync") {
                    row(label: "Last synced", value: lastSyncedText)
                    
                    HStack {
                        Text("Status")
                        Spacer()
                        if service.isSyncing {
                            statusBadge("Syncing...", color: .blue, spinning: true)
                        } else if service.isOutOfDate {
                            statusBadge("Out of date", color: .orange)
                        } else {
                            statusBadge("Up to date", color: .green)
                        }
                    }
                }
                
                // MARK: - Chart Build
                
                Section("Charts") {
                    row(label: "Last built", value: lastBuiltText)
                    
                    HStack {
                        Text("Status")
                        Spacer()
                        if chartService.isBuilding {
                            statusBadge("Building...", color: .blue, spinning: true)
                        } else if let err = chartService.buildError {
                            statusBadge("Error", color: .red)
                                .help(err)
                        } else if chartService.isDue {
                            statusBadge("Due for rebuild", color: .orange)
                        } else {
                            statusBadge("Up to date", color: .green)
                        }
                    }
                    
                    if let err = chartService.buildError {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                
                
                Section {
                    actionButton(
                        title: service.isSyncing ? "Syncing Library…" : (chartService.isBuilding ? "Building Charts…" : "Sync & Build Now"),
                        disabled: (service.isSyncing || chartService.isBuilding)
                    ) {
                        Task {
                            await service.syncLibrary()
                            
                            await chartService.build(
                                songs: service.songs,
                                albums: service.albums,
                                artists: service.artists
                            )
                        }
                    }
                }
                
                // MARK: - Cloud Configuration
                Section(header: Text("Cloud Configuration")) {
                    TextField("Account Name", text: $cosmos.accountName)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    SecureField("Master Key", text: $cosmos.masterKey)
                    TextField("Database", text: $cosmos.databaseId)
                    TextField("Container", text: $cosmos.containerId)
                }
                
                Section {
                    actionButton(
                        title: "Update Configuration",
                        disabled: chartService.isBuilding || service.isSyncing
                    ) {
                        Task {
                            cosmos.saveConfiguration()
                            // Haptic feedback
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        }
                    }
                }
            }
            .navigationTitle("Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func row(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private func statusBadge(_ text: String, color: Color, spinning: Bool = false) -> some View {
        HStack(spacing: 6) {
            if spinning {
                ProgressView().scaleEffect(0.8)
            }
            Text(text).foregroundStyle(color)
        }
    }
}
