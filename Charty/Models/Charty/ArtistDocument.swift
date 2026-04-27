struct ArtistDocument: MusicDocument {
    let id: String
    var type: String = "artist"
    let name: String
    var playCount: Int
    var playHistory: [PlayPeriod]
}
