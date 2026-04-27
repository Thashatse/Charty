protocol MusicDocument: Codable {
    var id: String { get }
    var type: String { get }
    var playCount: Int { get set }
    var playHistory: [PlayPeriod] { get set }
}
