import Foundation
import MusicKit

struct AlbumItem: Identifiable, Codable {
    let id: String
    let title: String
    let artist: String
    let playCount: Int
    let releaseDate: Date?
    let libraryAddedDate: Date?
    let artwork: Artwork?
    let searchTarget: String
    
    var award: Award? {
            let streamingDate = Calendar.current.date(from: DateComponents(year: 2015, month: 1, day: 1))!
            let isPreStreamingLaunch = releaseDate != nil && releaseDate! < streamingDate
            
            let doubleDiamondReq = isPreStreamingLaunch ? 1500 : 3000
            let diamondReq = isPreStreamingLaunch ? 750 : 1500
            let platinumReq = isPreStreamingLaunch ? 500 : 1000
            let goldReq = isPreStreamingLaunch ? 200 : 400
            
            if playCount >= doubleDiamondReq { return .doubleDiamond }
            if playCount >= diamondReq { return .diamond }
            if playCount >= platinumReq { return .platinum }
            if playCount >= goldReq { return .gold }
            return nil
        }
}
