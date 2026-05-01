import Foundation

struct ChartDocument: Codable {
    var id: String
    var userid: String
    var ChartData: [Chart]
    var PlayData: [SongPlay]
    var Periods: [Period]
}
