struct SongDocument: MusicDocument {
    let id: String
    var type: String = "song"
    let title: String
    let artist: String
    let artistID: String?
    let albumTitle: String
    let albumID: String?
    var playCount: Int 
    var playHistory: [PlayPeriod]
}
