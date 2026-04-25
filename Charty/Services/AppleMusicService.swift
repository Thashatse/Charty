import Combine
import MusicKit
import Foundation

@MainActor
class AppleMusicService: ObservableObject {
    @Published var songs: [SongItem] = []
    @Published var albums: [AlbumItem] = []
    @Published var artists: [ArtistItem] = []
    @Published var isLoading = false

    func loadLibrary() async {
        isLoading = true
        defer { isLoading = false }

        let status = await MusicAuthorization.request()
        guard status == .authorized else { return }

        do {
            // 1. Fetch Songs (This is our "Source of Truth" for play counts)
            var songRequest = MusicLibraryRequest<MusicKit.Song>()
            // Optional: increase limit if you have a large library
            songRequest.limit = 1000000
            
            let songResponse = try await songRequest.response()
            
            let fetchedSongs = songResponse.items.map {
                SongItem(
                    id: $0.id.rawValue,
                    title: $0.title,
                    artist: $0.artistName,
                    albumTitle: $0.albumTitle ?? "Unknown Album", // Added this to SongItem struct
                    playCount: $0.playCount ?? 0,
                    lastPlayed: $0.lastPlayedDate
                )
            }.sorted { $0.playCount > $1.playCount }
            
            self.songs = fetchedSongs

            // 2. Aggregate Album Charts from fetchedSongs
            self.albums = aggregateAlbumCharts(from: fetchedSongs)

            // 3. Aggregate Artist Charts from fetchedSongs
            self.artists = aggregateArtistCharts(from: fetchedSongs)
            
        } catch {
            print("Error: \(error)")
        }
    }

    // NEW: Aggregate Album Charts
    private func aggregateAlbumCharts(from songs: [SongItem]) -> [AlbumItem] {
        // We use a dictionary where the key is "AlbumTitle - ArtistName"
        // to handle self-titled albums by different artists correctly
        var albumData: [String: (title: String, artist: String, count: Int)] = [:]
        
        for song in songs {
            let key = "\(song.albumTitle ?? "") - \(song.artist)"
            let current = albumData[key] ?? (title: song.albumTitle, artist: song.artist, count: 0)
            albumData[key] = (title: current.title, artist: current.artist, count: current.count + song.playCount) as? (title: String, artist: String, count: Int)
        }
        
        return albumData.map { (key, value) in
            AlbumItem(id: key, title: value.title, artist: value.artist, playCount: value.count)
        }.sorted { $0.playCount > $1.playCount }
    }

    private func aggregateArtistCharts(from songs: [SongItem]) -> [ArtistItem] {
        var counts: [String: Int] = [:]
        for song in songs {
            counts[song.artist, default: 0] += song.playCount
        }
        
        return counts.map { ArtistItem(id: $0.key, name: $0.key, playCount: $0.value) }
            .sorted { $0.playCount > $1.playCount }
    }
}
