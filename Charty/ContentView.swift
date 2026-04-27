import SwiftUI

struct ContentView: View {
    @StateObject private var service = AppleMusicService()
    @State private var selectedChart = 0

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Chart Type", selection: $selectedChart) {
                    Text("Songs").tag(0)
                    Text("Albums").tag(1)
                    Text("Artists").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                Group {
                    if service.isLoading {
                        ProgressView("Loading your charts...")
                            .frame(maxHeight: .infinity)
                    } else {
                        List {
                            if selectedChart == 0 {
                                ForEach(Array(service.songs.prefix(500).enumerated()), id: \.element.id) { index, song in
                                    ChartRow(rank: index + 1, title: song.title, subtitle: song.artist, stat: song.playCount)
                                }
                            } else if selectedChart == 1 {
                                ForEach(Array(service.albums.prefix(100).enumerated()), id: \.element.id) { index, album in
                                    ChartRow(rank: index + 1, title: album.title, subtitle: album.artist, stat: album.playCount, award: album.award)
                                }
                            } else {
                                ForEach(Array(service.artists.prefix(100).enumerated()), id: \.element.id) { index, artist in
                                    ChartRow(rank: index + 1, title: artist.name, subtitle: "Total Plays", stat: artist.playCount, award: artist.award)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Charts")
            .task {
                if service.songs.isEmpty {
                    await service.loadLibrary()
                }
            }
        }
    }
}
