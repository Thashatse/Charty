import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var musicService: AppleMusicService
    @EnvironmentObject private var chartService: ChartService
    @State private var activeTab = 0
    @State private var showingSyncSheet = false
    @State private var searchText = ""
    
    private let period = PeriodHelper.getCurrentPeriod()
    
    var body: some View {
        TabView(selection: $activeTab) {
            AllTimeView(searchText: searchText)
                .tabItem { Label("Lifetime", systemImage: "trophy") }
                .tag(0)
            
            BuildingChartView(searchText: searchText)
                .tabItem { Label("Building", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(1)
        }
        .searchable(text: $searchText, placement: .automatic, prompt: "Search...")
        .navigationTitle("Charts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(activeTab == 0 ? "Lifetime Charts" : "Building • " + period.displayName)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingSyncSheet = true } label: {
                    Image(systemName: "arrow.triangle.2.circlepath.circle")
                        .symbolEffect(.rotate, isActive: (musicService.isSyncing || chartService.isBuilding))
                        .foregroundStyle((musicService.isOutOfDate || chartService.isDue) ? .orange : .accentColor)
                }
            }
        }
        .sheet(isPresented: $showingSyncSheet) {
            SyncStatusView(service: musicService, chartService: chartService)
        }
        .task {
            await musicService.loadOnLaunch()
        }
    }
}

