struct AlbumDocument: MusicDocument {
    let id: String
    var type: String = "album"
    let title: String
    let artist: String
    var playCount: Int
    var playHistory: [PlayPeriod]
}
