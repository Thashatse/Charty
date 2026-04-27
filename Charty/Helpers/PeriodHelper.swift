import Foundation

struct PeriodHelper {
    static func getCurrentPeriod() -> (id: String, start: String, end: String) {
        var calendar = Calendar.current
        calendar.firstWeekday = 6 // Friday
        
        let now = Date()
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_ZA")
        
        // Find the start of the current week (Friday)
        var startOfWeek = Date()
        var interval: TimeInterval = 0
        _ = calendar.dateInterval(of: .weekOfYear, start: &startOfWeek, interval: &interval, for: now)
        
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? now
        
        let weekNo = calendar.component(.weekOfYear, from: startOfWeek)
        let yearNo = calendar.component(.yearForWeekOfYear, from: startOfWeek)
        
        return (
            id: "\(yearNo)-W\(weekNo)",
            start: df.string(from: startOfWeek),
            end: df.string(from: endOfWeek)
        )
    }
}
