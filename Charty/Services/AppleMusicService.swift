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
        return Date().timeIntervalSince(last) > syncIntervalHours * 3600
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
        
        // User must authorise apple music access
        let status = await MusicAuthorization.request()
        guard status == .authorized else { return }
        
        do {
            var songRequest = MusicLibraryRequest<MusicKit.Song>()
            songRequest.limit = 1_000_000
            let songResponse = try await songRequest.response()
            let rawSongs = songResponse.items
            
            var fetchedSongs: [SongItem] = []
            var albumData: [String: (title: String, artist: String, count: Int, releaseDate: Date?, libraryAddedDate: Date?, artwork: Artwork?, searchTarget: String)] = [:]
            var artistData: [String: (name: String, count: Int, searchTarget: String, artwork: Artwork?)] = [:]
            
            // Metadata Caches
            var albumArtistCache: [String: String] = [:]
            var albumArtworkCache: [String: Artwork] = [:]
            var artistArtworkCache: [String: Artwork] = [:]
            
            for song in rawSongs {
                let albumTitle = song.albumTitle ?? "Unknown Album"
                let songArtist = song.artistName
                let playCount = song.playCount ?? 0
                
                var resolvedAlbumArtist = albumArtistCache[albumTitle]
                var resolvedTrackArtists = [songArtist]
                var needsDetailCall = false
                
                let isCollaboration = songArtist.contains("&") ||
                songArtist.lowercased().contains("feat.") ||
                songArtist.contains(",")
                
                // Trigger .with(.artists, .albums) if metadata is missing from cache
                if resolvedAlbumArtist == nil {
                    needsDetailCall = true
                } else if albumArtworkCache[albumTitle] == nil && song.artwork == nil {
                    needsDetailCall = true
                } else if isCollaboration {
                    needsDetailCall = true
                } else if let albumArtist = resolvedAlbumArtist, songArtist != albumArtist {
                    needsDetailCall = true
                } else if artistArtworkCache[songArtist] == nil {
                    needsDetailCall = true
                }
                
                if needsDetailCall {
                    let detailed = (try? await song.with(.artists, .albums)) ?? song
                    
                    // Resolve & Cache Album Artist
                    let foundAlbumArtist = detailed.albums?.first?.artistName ?? songArtist
                    resolvedAlbumArtist = foundAlbumArtist
                    albumArtistCache[albumTitle] = foundAlbumArtist
                    
                    // Resolve & Cache Album Artwork
                    if let albumArt = detailed.albums?.first?.artwork {
                        albumArtworkCache[albumTitle] = albumArt
                    }
                    
                    // Resolve & Filter Guest List
                    var artistList = detailed.artists?.map { $0.name } ?? []
                    if artistList.count == 1 {
                        let singleName = artistList[0]
                        let isCombined = singleName.contains("&") || singleName.contains(",") || singleName.lowercased().contains("feat.")
                        let isMissingFeatures = isCollaboration && artistList.count == 1
                        
                        if isCombined || isMissingFeatures {
                            // Reject and force manual split
                            artistList = []
                        }
                    }
                    if artistList.isEmpty {
                        // Fallback manual split
                        resolvedTrackArtists = songArtist.components(separatedBy: CharacterSet(charactersIn: "&,"))
                            .map { $0.replacingOccurrences(of: "feat.", with: "", options: .caseInsensitive) }
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }
                    } else {
                        resolvedTrackArtists = artistList
                    }
                    let albumArtistNormalized = foundAlbumArtist.normalizedForSearch
                    let alreadyIncluded = resolvedTrackArtists.contains { $0.normalizedForSearch == albumArtistNormalized }
                    if !alreadyIncluded {
                        resolvedTrackArtists.append(foundAlbumArtist)
                    }
                    
                    // Resolve & Cache Artist Artwork
                    if let artists = detailed.artists {
                        for artist in artists {
                            if artistArtworkCache[artist.name] == nil {
                                artistArtworkCache[artist.name] = artist.artwork
                            }
                        }
                    }
                } else {
                    resolvedTrackArtists = [songArtist]
                }
                
                let finalAlbumArtist = resolvedAlbumArtist ?? songArtist
                let albumKey = "\(albumTitle)-\(finalAlbumArtist)"
                let finalAlbumArtwork = song.artwork ?? albumArtworkCache[albumTitle]
                
                fetchedSongs.append(SongItem(
                    id: song.id.rawValue,
                    title: song.title,
                    artist: songArtist,
                    artistNames: resolvedTrackArtists,
                    albumArtist: finalAlbumArtist,
                    artistID: nil,
                    albumTitle: albumTitle,
                    albumID: nil,
                    playCount: playCount,
                    lastPlayed: song.lastPlayedDate,
                    trackNumber: song.trackNumber ?? 0,
                    releaseDate: song.releaseDate,
                    libraryAddedDate: song.libraryAddedDate,
                    artwork: finalAlbumArtwork
                ))
                
                // Update Album Accumulator
                let currentAlbum = albumData[albumKey] ?? (title: albumTitle, artist: finalAlbumArtist, count: 0, releaseDate: song.releaseDate, libraryAddedDate: song.libraryAddedDate, artwork: finalAlbumArtwork, searchTarget: "")
                
                albumData[albumKey] = (title: currentAlbum.title, artist: currentAlbum.artist, count: currentAlbum.count + playCount, releaseDate: currentAlbum.releaseDate, libraryAddedDate: currentAlbum.libraryAddedDate, artwork: currentAlbum.artwork ?? finalAlbumArtwork, searchTarget: currentAlbum.searchTarget + " | " + song.title)
                
                // Update Artist Accumulator
                for name in resolvedTrackArtists {
                    let currentArtist = artistData[name] ?? (name: name, count: 0, searchTarget: "", artwork: artistArtworkCache[name])
                    
                    artistData[name] = (name: name, count: currentArtist.count + playCount, searchTarget: currentArtist.searchTarget + " | " + song.title, artwork: currentArtist.artwork ?? artistArtworkCache[name])
                }
            }
            
            await MainActor.run {
                self.songs = fetchedSongs.sorted { $0.playCount > $1.playCount }
                
                self.albums = albumData.map { AlbumItem(id: $0.key, title: $0.value.title, artist: $0.value.artist, playCount: $0.value.count, releaseDate: $0.value.releaseDate, libraryAddedDate: $0.value.libraryAddedDate, artwork: $0.value.artwork, searchTarget: $0.value.searchTarget) }.sorted { $0.playCount > $1.playCount }
                
                self.artists = artistData.map { ArtistItem(id: $0.key, name: $0.value.name, playCount: $0.value.count, searchTarget: $0.value.searchTarget, artwork: $0.value.artwork) }.sorted { $0.playCount > $1.playCount }
            }
            
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
