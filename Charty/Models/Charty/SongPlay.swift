struct SongPlay: Codable {
    var SongId: String
    var ArtistId: String
    var AlbumId: String
    var PlayHistory: [PlayHistory]
}

struct PlayHistory: Codable {
    var PeriodId: String
    var PeriodPlays: String
    var TotalPlays: String
    var PerDayPlays: [DayPlays]
}

struct DayPlays: Codable {
    var date: String   // "yyyy-MM-dd"
    var plays: String
}
