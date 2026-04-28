import SwiftUI

struct SyncStatusView: View {
    @ObservedObject var service: AppleMusicService
    @Environment(\.dismiss) var dismiss
    
    private var lastSyncedText: String {
        guard let date = service.lastSynced else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Sync Status") {
                    HStack {
                        Text("Last synced")
                        Spacer()
                        Text(lastSyncedText)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Status")
                        Spacer()
                        if service.isSyncing {
                            HStack(spacing: 6) {
                                ProgressView().scaleEffect(0.8)
                                Text("Syncing...")
                                    .foregroundStyle(.secondary)
                            }
                        } else if service.isOutOfDate {
                            Text("Out of date")
                                .foregroundStyle(.orange)
                        } else {
                            Text("Up to date")
                                .foregroundStyle(.green)
                        }
                    }
                }
                
                Section {
                    Button {
                        Task { await service.syncLibrary() }
                    } label: {
                        HStack {
                            Spacer()
                            Text(service.isSyncing ? "Syncing..." : "Sync Now")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(service.isSyncing)
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
