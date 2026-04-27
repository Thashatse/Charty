import Foundation
import MusicKit

struct SongItem: Identifiable {
    let id: String
    let title: String
    let artist: String
    let albumArtist: String
    let artistID: String?
    let albumTitle: String
    let albumID: String?
    let playCount: Int
    let lastPlayed: Date?
    let trackNumber: Int
    let releaseDate: Date?
    let artwork: Artwork?
    
    var award: Award? {
        if playCount >= 500 { return .doubleDiamond }
        if playCount >= 250 { return .diamond }
        if playCount >= 100 { return .platinum }
        if playCount >= 40 { return .gold }
            return nil
        }
}
