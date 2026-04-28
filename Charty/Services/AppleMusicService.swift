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
    
    private let lastSyncedKey = "charty_last_synced"
    private let songcacheKey = "charty_song_cache"
    private let albumCacheKey = "charty_albums_cache"
    private let artistCacheKey = "charty_artists_cache"
    
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
        let hasCache = !songs.isEmpty && !albums.isEmpty && !artists.isEmpty
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
            songRequest.limit = 1_000_000
            let songResponse = try await songRequest.response()
            
            var fetchedSongs: [SongItem] = []
            var albumData: [String: (title: String, artist: String, count: Int, releaseDate: Date?, libraryAddedDate: Date?, artwork: Artwork?, searchTarget: String)] = [:]
            var artistData: [String: (name: String, count: Int, searchTarget: String)] = [:]
            var resolvedAlbumArtists: [String: String] = [:]
            
            for song in songResponse.items {
                let playCount = song.playCount ?? 0
                let albumTitle = song.albumTitle ?? "Unknown Album"
                
                // Only fetch album relationship once per unique album title
                let albumArtist: String
                if let cached = resolvedAlbumArtists[albumTitle] {
                    albumArtist = cached
                } else {
                    let detailed = (try? await song.with(.albums)) ?? song
                    albumArtist = detailed.albums?.first?.artistName ?? song.artistName
                    resolvedAlbumArtists[albumTitle] = albumArtist
                }
                
                let albumKey = "\(albumTitle)-\(albumArtist)"
                let artistKey = albumArtist
                
                // Build song
                fetchedSongs.append(SongItem(
                    id: song.id.rawValue,
                    title: song.title,
                    artist: song.artistName,
                    albumArtist: albumArtist,
                    artistID: nil,
                    albumTitle: albumTitle,
                    albumID: nil,
                    playCount: playCount,
                    lastPlayed: song.lastPlayedDate,
                    trackNumber: song.trackNumber ?? 0,
                    releaseDate: song.releaseDate,
                    libraryAddedDate: song.libraryAddedDate,
                    artwork: song.artwork
                ))
                
                // Accumulate album
                let currentAlbum = albumData[albumKey] ?? (
                    title: albumTitle,
                    artist: albumArtist,
                    count: 0,
                    releaseDate: song.releaseDate,
                    libraryAddedDate: song.libraryAddedDate,
                    artwork: song.artwork,
                    searchTarget: ""
                )
                albumData[albumKey] = (
                    title: currentAlbum.title,
                    artist: currentAlbum.artist,
                    count: currentAlbum.count + playCount,
                    releaseDate: currentAlbum.releaseDate,
                    libraryAddedDate: currentAlbum.libraryAddedDate,
                    artwork: currentAlbum.artwork,
                    searchTarget: currentAlbum.searchTarget + " | " + song.title
                )
                
                // Accumulate artist
                let currentArtist = artistData[artistKey] ?? (name: albumArtist, count: 0, searchTarget: "")
                artistData[artistKey] = (
                    name: currentArtist.name,
                    count: currentArtist.count + playCount,
                    searchTarget: currentArtist.searchTarget + " | " + song.title
                )
            }
            
            self.songs = fetchedSongs.sorted {
                if $0.playCount != $1.playCount {
                    return $0.playCount > $1.playCount
                }
                let date0 = $0.libraryAddedDate ?? $0.releaseDate ?? .distantPast
                let date1 = $1.libraryAddedDate ?? $1.releaseDate ?? .distantPast
                return date0 < date1
            }
            
            self.albums = albumData.map {
                AlbumItem(
                    id: $0.key,
                    title: $0.value.title,
                    artist: $0.value.artist,
                    playCount: $0.value.count,
                    releaseDate: $0.value.releaseDate,
                    libraryAddedDate: $0.value.libraryAddedDate,
                    artwork: $0.value.artwork,
                    searchTarget: $0.value.searchTarget
                )
            }.sorted {
                if $0.playCount != $1.playCount {
                    return $0.playCount > $1.playCount
                }
                let date0 = $0.libraryAddedDate ?? $0.releaseDate ?? .distantPast
                let date1 = $1.libraryAddedDate ?? $1.releaseDate ?? .distantPast
                return date0 < date1
            }
            
            self.artists = artistData.map {
                ArtistItem(
                    id: $0.key,
                    name: $0.value.name,
                    playCount: $0.value.count,
                    searchTarget: $0.value.searchTarget
                )
            }.sorted { $0.playCount > $1.playCount }
            
            saveToCache()
            lastSynced = Date()
            UserDefaults.standard.set(lastSynced, forKey: lastSyncedKey)
            
        } catch {
            print("Sync error: \(error)")
        }
    }
    
    private func saveToCache() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(songs) {
            UserDefaults.standard.set(data, forKey: songcacheKey)
        }
        if let data = try? encoder.encode(albums) {
            UserDefaults.standard.set(data, forKey: albumCacheKey)
        }
        if let data = try? encoder.encode(artists) {
            UserDefaults.standard.set(data, forKey: artistCacheKey)
        }
    }
    
    private func loadFromCache() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: songcacheKey),
           let cached = try? decoder.decode([SongItem].self, from: data) {
            songs = cached
        }
        if let data = UserDefaults.standard.data(forKey: albumCacheKey),
           let cached = try? decoder.decode([AlbumItem].self, from: data) {
            albums = cached
        }
        if let data = UserDefaults.standard.data(forKey: artistCacheKey),
           let cached = try? decoder.decode([ArtistItem].self, from: data) {
            artists = cached
        }
    }
}
