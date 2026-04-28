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
    @Published var lastSynced: Date? = nil
    
    private let cacheKey = "charty_cache"
    private let lastSyncedKey = "charty_last_synced"
    
    init() {
        loadFromCache()
        lastSynced = UserDefaults.standard.object(forKey: lastSyncedKey) as? Date
    }
    
    private let syncIntervalHours: Double = 6
    private let outOfDateHours: Double = 3
    
    var isOutOfDate: Bool {
        guard let last = lastSynced else { return true }
        return Date().timeIntervalSince(last) > outOfDateHours * 3600
    }
    
    func loadOnLaunch() async {
        let hasCache = !songs.isEmpty
        guard !hasCache else {
            if isOutOfDate {
                await syncLibrary()
            }
            return
        }
        
        isLoading = true
        await syncLibrary()
        isLoading = false
    }
    
    func syncLibrary() async {
        isSyncing = true
        defer { isSyncing = false }
        
        let status = await MusicAuthorization.request()
        guard status == .authorized else { return }
        
        do {
            var songRequest = MusicLibraryRequest<MusicKit.Song>()
            songRequest.limit = 1000000
            let songResponse = try await songRequest.response()
            
            var fetchedSongs: [SongItem] = []
            for song in songResponse.items {
                let detailed = (try? await song.with(.albums, .artists)) ?? song
                fetchedSongs.append(SongItem(
                    id: detailed.id.rawValue,
                    title: detailed.title,
                    artist: detailed.artistName,
                    albumArtist: detailed.albums?.first?.artistName ?? detailed.artistName,
                    artistID: detailed.artists?.first?.id.rawValue,
                    albumTitle: detailed.albumTitle ?? "Unknown Album",
                    albumID: detailed.albums?.first?.id.rawValue,
                    playCount: detailed.playCount ?? 0,
                    lastPlayed: detailed.lastPlayedDate,
                    trackNumber: detailed.trackNumber ?? 0,
                    releaseDate: detailed.releaseDate,
                    artwork: detailed.artwork
                ))
            }
            
            fetchedSongs.sort { $0.playCount > $1.playCount }
            
            self.songs = fetchedSongs
            self.albums = aggregateAlbumCharts(from: fetchedSongs)
            self.artists = aggregateArtistCharts(from: fetchedSongs)
            
            saveToCache()
            lastSynced = Date()
            UserDefaults.standard.set(lastSynced, forKey: lastSyncedKey)
            
        } catch {
            print("Error: \(error)")
        }
    }
    
    private func aggregateAlbumCharts(from songs: [SongItem]) -> [AlbumItem] {
        var data: [String: (title: String, artist: String, count: Int, releaseDate: Date?, artwork: Artwork?, searchTarget: String)] = [:]
        
        for song in songs {
            let key = song.albumID ?? "\(song.albumTitle)-\(song.albumArtist)"
            let current = data[key] ?? (title: song.albumTitle, artist: song.albumArtist, count: 0, releaseDate: song.releaseDate,
                                        artwork: song.artwork, searchTarget: "")
            data[key] = (title: current.title, artist: current.artist, count: current.count + song.playCount, releaseDate: current.releaseDate,
                         artwork: current.artwork, searchTarget: current.searchTarget + " | " + song.title)
        }
        
        return data.map {
            AlbumItem(id: $0.key, title: $0.value.title, artist: $0.value.artist, playCount: $0.value.count, releaseDate: $0.value.releaseDate,
                      artwork: $0.value.artwork, searchTarget: $0.value.searchTarget)
        }.sorted { $0.playCount > $1.playCount }
    }
    
    private func aggregateArtistCharts(from songs: [SongItem]) -> [ArtistItem] {
        var data: [String: (name: String, count: Int, searchTarget: String)] = [:]
        
        for song in songs {
            let key = song.artistID ?? song.albumArtist
            let current = data[key] ?? (name: song.albumArtist, count: 0, searchTarget: song.albumTitle)
            data[key] = (name: current.name, count: current.count + song.playCount,
                         searchTarget: current.searchTarget + " | " + song.title)
        }
        return data.map {
            ArtistItem(id: $0.key, name: $0.value.name, playCount: $0.value.count, searchTarget: $0.value.searchTarget)
        }.sorted { $0.playCount > $1.playCount }
    }
    
    private func saveToCache() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(songs) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }
    
    private func loadFromCache() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cached = try? JSONDecoder().decode([SongItem].self, from: data)
        else { return }
        
        songs = cached
        albums = aggregateAlbumCharts(from: cached)
        artists = aggregateArtistCharts(from: cached)
    }
}
