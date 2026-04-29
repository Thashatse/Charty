import Foundation
import MusicKit

struct SongItem: Identifiable, Codable {
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
    let libraryAddedDate: Date?
    // Artwork excluded from cache — not Codable
    let artwork: Artwork?
    
    var award: Award? {
            let streamingDate = Calendar.current.date(from: DateComponents(year: 2015, month: 1, day: 1))!
            let isPreStreamingLaunch = releaseDate != nil && releaseDate! < streamingDate
            
            let doubleDiamondReq = isPreStreamingLaunch ? 250 : 500
            let diamondReq = isPreStreamingLaunch ? 125 : 250
            let platinumReq = isPreStreamingLaunch ? 50 : 100
            let goldReq = isPreStreamingLaunch ? 20 : 40
            
            if playCount >= doubleDiamondReq { return .doubleDiamond }
            if playCount >= diamondReq { return .diamond }
            if playCount >= platinumReq { return .platinum }
            if playCount >= goldReq { return .gold }
            return nil
        }
}
