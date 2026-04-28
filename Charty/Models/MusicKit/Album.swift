import Foundation
import MusicKit

struct AlbumItem: Identifiable {
    let id: String
    let title: String
    let artist: String
    let playCount: Int
    let releaseDate: Date?
    let artwork: Artwork?
    let searchTarget: String
    
    var award: Award? {
        if playCount >= 3000 { return .doubleDiamond }
        if playCount >= 1500 { return .diamond }
        if playCount >= 1000 { return .platinum }
        if playCount >= 400 { return .gold }
            return nil
        }
}
