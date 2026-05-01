import SwiftUI

struct BuildingChartView: View {
    @EnvironmentObject private var musicService: AppleMusicService
    @EnvironmentObject private var chartService: ChartService
    @State private var selectedChart = 0
    let searchText: String

    var body: some View {
        VStack(spacing: 0) {
            Picker("Chart Type", selection: $selectedChart) {
                Text("Songs").tag(0)
                Text("Albums").tag(1)
                Text("Artists").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()

            let chart = chartService.buildingChart

            if chart.singles.isEmpty && chart.albums.isEmpty && chart.artists.isEmpty {
                ContentUnavailableView(
                    "No chart data yet",
                    systemImage: "chart.bar",
                    description: Text("Sync your library to start building this week's chart.")
                )
            } else {
                List {
                    if selectedChart == 0 {
                        let filtered = filteredSingles(chart.singles)
                        ForEach(filtered, id: \.songId) { entry in
                            if let song = musicService.songs.first(where: { $0.id == entry.songId }) {
                                NavigationLink(destination: SongDetail(
                                    song: song,
                                    allSongs: musicService.songs,
                                    allAlbums: musicService.albums,
                                    allArtists: musicService.artists
                                )) {
                                    ChartRow(
                                        rank: entry.rank,
                                        title: song.title,
                                        subtitle: song.artist,
                                        stat: entry.plays,
                                        award: nil,
                                        artwork: song.artwork,
                                        isNowPlaying: musicService.nowPlayingSong?.id == song.id
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else if selectedChart == 1 {
                        let filtered = filteredAlbums(chart.albums)
                        ForEach(filtered, id: \.albumId) { entry in
                            if let album = musicService.albums.first(where: {
                                $0.id == entry.albumId || $0.title == entry.albumId
                            }) {
                                NavigationLink(destination: AlbumDetail(
                                    album: album,
                                    allSongs: musicService.songs,
                                    allAlbums: musicService.albums,
                                    allArtists: musicService.artists
                                )) {
                                    ChartRow(
                                        rank: entry.rank,
                                        title: album.title,
                                        subtitle: album.artist,
                                        stat: entry.plays,
                                        award: nil,
                                        artwork: album.artwork
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        let filtered = filteredArtists(chart.artists)
                        ForEach(filtered, id: \.artistId) { entry in
                            if let artist = musicService.artists.first(where: {
                                $0.id == entry.artistId || $0.name == entry.artistId
                            }) {
                                NavigationLink(destination: ArtistDetail(
                                    artist: artist,
                                    allSongs: musicService.songs,
                                    allAlbums: musicService.albums,
                                    allArtists: musicService.artists
                                )) {
                                    ChartRow(
                                        rank: entry.rank,
                                        title: artist.name,
                                        subtitle: "",
                                        stat: entry.plays,
                                        award: nil,
                                        artwork: artist.artwork
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Search filters

    private func filteredSingles(_ entries: [(rank: Int, songId: String, plays: Int)]) -> [(rank: Int, songId: String, plays: Int)] {
        guard !searchText.isEmpty else { return entries }
        return entries.filter { entry in
            guard let song = musicService.songs.first(where: { $0.id == entry.songId }) else { return false }
            return "\(song.title) \(song.artist) \(song.albumTitle)"
                .localizedCaseInsensitiveContains(searchText)
        }
    }

    private func filteredAlbums(_ entries: [(rank: Int, albumId: String, plays: Int)]) -> [(rank: Int, albumId: String, plays: Int)] {
        guard !searchText.isEmpty else { return entries }
        return entries.filter { entry in
            guard let album = musicService.albums.first(where: { $0.id == entry.albumId || $0.title == entry.albumId }) else { return false }
            return "\(album.title) \(album.artist)"
                .localizedCaseInsensitiveContains(searchText)
        }
    }

    private func filteredArtists(_ entries: [(rank: Int, artistId: String, plays: Int)]) -> [(rank: Int, artistId: String, plays: Int)] {
        guard !searchText.isEmpty else { return entries }
        return entries.filter { entry in
            guard let artist = musicService.artists.first(where: { $0.id == entry.artistId || $0.name == entry.artistId }) else { return false }
            return artist.name.localizedCaseInsensitiveContains(searchText)
        }
    }
}
