import MusicKit

struct ArtistItem: Identifiable, Codable {
    let id: String
    let name: String
    let playCount: Int
    let searchTarget: String
    let artwork: Artwork?
    
    var award: Award? {
        if playCount >= 10000 { return .doubleDiamond }
        if playCount >= 5000 { return .diamond }
        if playCount >= 2500 { return .platinum }
        if playCount >= 1000 { return .gold }
        if playCount >= 400 { return .silver }
            return nil
        }
}
