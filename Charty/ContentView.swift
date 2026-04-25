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
                                ForEach(Array(service.songs.enumerated()), id: \.element.id) { index, song in
                                    ChartRow(rank: index + 1, title: song.title, subtitle: song.artist, stat: song.playCount)
                                }
                            } else if selectedChart == 1 {
                                ForEach(Array(service.albums.enumerated()), id: \.element.id) { index, album in
                                    ChartRow(rank: index + 1, title: album.title, subtitle: album.artist, stat: album.playCount)
                                }
                            } else {
                                ForEach(Array(service.artists.enumerated()), id: \.element.id) { index, artist in
                                    ChartRow(rank: index + 1, title: artist.name, subtitle: "Total Plays", stat: artist.playCount)
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

struct ChartRow: View {
    let rank: Int
    let title: String
    let subtitle: String
    let stat: Int // Changed from String to Int

    // Custom formatter to use a space as a separator
    private var formattedStat: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " " // Set the space here
        return formatter.string(from: NSNumber(value: stat)) ?? "\(stat)"
    }

    var body: some View {
        HStack {
            Text("\(rank)")
                .font(.system(.body, design: .monospaced))
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .frame(width: 35, alignment: .leading)
            
            VStack(alignment: .leading) {
                Text(title)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(formattedStat) // Uses the space-separated string
                .font(.subheadline)
                .foregroundStyle(.blue)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 2)
    }
}
