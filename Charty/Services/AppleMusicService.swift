import Combine
import MusicKit
import Foundation

@MainActor
class AppleMusicService: ObservableObject {
    @Published var songs: [SongItem] = []
    @Published var albums: [AlbumItem] = []
    @Published var artists: [ArtistItem] = []
    @Published var isLoading = false
    @Published var isSyncing = false

    func loadLibrary() async {
        isLoading = true
        defer { isLoading = false }

        let status = await MusicAuthorization.request()
        guard status == .authorized else { return }

        do {
            var songRequest = MusicLibraryRequest<MusicKit.Song>()
            songRequest.limit = 1000000
            let songResponse = try await songRequest.response()
            
            let fetchedSongs = songResponse.items.map {
                SongItem(
                    id: $0.id.rawValue,
                    title: $0.title,
                    artist: $0.artistName,
                    artistID: $0.artists?.first?.id.rawValue,
                    albumTitle: $0.albumTitle ?? "Unknown Album",
                    albumID: $0.albums?.first?.id.rawValue,
                    playCount: $0.playCount ?? 0,
                    lastPlayed: $0.lastPlayedDate
                )
            }.sorted { $0.playCount > $1.playCount }
            
            self.songs = fetchedSongs
            self.albums = aggregateAlbumCharts(from: fetchedSongs)
            self.artists = aggregateArtistCharts(from: fetchedSongs)
            
        } catch {
            print("Error: \(error)")
        }
    }
    
    private func aggregateAlbumCharts(from songs: [SongItem]) -> [AlbumItem] {
        var data: [String: (title: String, artist: String, count: Int)] = [:]
        for song in songs {
            let key = song.albumID ?? "\(song.albumTitle)-\(song.artist)"
            let current = data[key] ?? (title: song.albumTitle, artist: song.artist, count: 0)
            data[key] = (title: current.title, artist: current.artist, count: current.count + song.playCount)
        }
        return data.map { AlbumItem(id: $0.key, title: $0.value.title, artist: $0.value.artist, playCount: $0.value.count) }.sorted { $0.playCount > $1.playCount }
    }

    private func aggregateArtistCharts(from songs: [SongItem]) -> [ArtistItem] {
        var data: [String: (name: String, count: Int)] = [:]
        for song in songs {
            let key = song.artistID ?? song.artist
            let current = data[key] ?? (name: song.artist, count: 0)
            data[key] = (name: current.name, count: current.count + song.playCount)
        }
        return data.map { ArtistItem(id: $0.key, name: $0.value.name, playCount: $0.value.count) }.sorted { $0.playCount > $1.playCount }
    }
}
