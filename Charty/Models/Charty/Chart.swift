struct Chart: Codable {
    var albums: ChartCategory
    var artist: ChartCategory
    var single: ChartCategory
}

struct ChartCategory: Codable {
    var Weekly: [WeeklyChart]
}

struct WeeklyChart: Codable {
    var PeriodId: String
    var entries: [ChartEntry]
}

struct ChartEntry: Codable {
    var SongId: String
    var position: Int
    var plays: Int
}
