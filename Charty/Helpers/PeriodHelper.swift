import Foundation

struct PeriodHelper {
    static func  getCurrentPeriod() -> (id: String, start: String, end: String, displayName: String) {
        var calendar = Calendar.current
        calendar.firstWeekday = 6
        
        let now = Date()
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_ZA")
        
        var startOfWeek = Date()
        var interval: TimeInterval = 0
        _ = calendar.dateInterval(of: .weekOfYear, start: &startOfWeek, interval: &interval, for: now)
        
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? now
        
        let weekNo = calendar.component(.weekOfYear, from: startOfWeek)
        let yearNo = calendar.component(.yearForWeekOfYear, from: startOfWeek)
        
        let displayDf = DateFormatter()
        displayDf.dateFormat = "dd/MM"
        displayDf.locale = Locale(identifier: "en_ZA")
        let displayName = "\(displayDf.string(from: startOfWeek)) – \(displayDf.string(from: endOfWeek))"
        
        return (
            id: "\(yearNo)W\(weekNo)",
            start: df.string(from: startOfWeek),
            end: df.string(from: endOfWeek),
            displayName: displayName
        )
    }
    
    /// Parses a "yyyy-MM-dd" period date string into a Date.
    /// Used when comparing song metadata dates against a known period boundary.
    static func date(from string: String) -> Date {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_ZA")
        // Fallback to .distantPast so comparisons always fail safely
        // rather than incorrectly attributing plays to a period.
        return df.date(from: string) ?? .distantPast
    }
}
