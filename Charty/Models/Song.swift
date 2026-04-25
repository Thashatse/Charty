import Foundation

struct SongItem: Identifiable {
    let id: String
    let title: String
    let artist: String
    let albumTitle: String?
    let playCount: Int
    let lastPlayed: Date?
}
