import Foundation

struct CadenceTimeframe {
    static let calendar: Calendar = {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current // Use local timezone
        return calendar
    }()
    
    static func nextStartDate(after date: Date, frequency: CadenceFrequency) -> Date {
        switch frequency {
        case .none:
            return date
            
        case .daily:
            // Next day at local midnight
            let midnight = calendar.startOfDay(for: date)
            return calendar.date(byAdding: .day, value: 1, to: midnight) ?? date
            
        case .weekly:
            // Next Monday at local midnight
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            components.weekOfYear! += 1
            components.weekday = 2 // Monday
            components.hour = 0
            components.minute = 0
            components.second = 0
            return calendar.date(from: components) ?? date
            
        case .monthly:
            // First day of next month at local midnight
            var components = calendar.dateComponents([.year, .month], from: date)
            components.month! += 1
            components.day = 1
            components.hour = 0
            components.minute = 0
            components.second = 0
            return calendar.date(from: components) ?? date
        }
    }
    
    static func calculateStartDate(
        from lastEndDate: Date,
        currentDate: Date,
        frequency: CadenceFrequency
    ) -> Date {
        switch frequency {
        case .none:
            return currentDate
            
        case .daily:
            // Find how many days we've missed
            let daysBetween = calendar.dateComponents([.day], from: lastEndDate, to: currentDate).day ?? 0
            // Start from the beginning of the current day
            return calendar.startOfDay(for: currentDate)
            
        case .weekly:
            // Find the most recent Monday at midnight
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate)
            components.weekday = 2 // Monday
            components.hour = 0
            components.minute = 0
            components.second = 0
            return calendar.date(from: components) ?? currentDate
            
        case .monthly:
            // Start from the first of the current month
            var components = calendar.dateComponents([.year, .month], from: currentDate)
            components.day = 1
            components.hour = 0
            components.minute = 0
            components.second = 0
            return calendar.date(from: components) ?? currentDate
        }
    }
    
    static func missedCycles(
        between lastEndDate: Date,
        and currentDate: Date,
        frequency: CadenceFrequency
    ) -> Int {
        switch frequency {
        case .none:
            return 0
            
        case .daily:
            let days = calendar.dateComponents([.day], from: lastEndDate, to: currentDate).day ?? 0
            return max(0, days - 1) // Subtract 1 because same-day doesn't count as missed
            
        case .weekly:
            let weeks = calendar.dateComponents([.weekOfYear], from: lastEndDate, to: currentDate).weekOfYear ?? 0
            return max(0, weeks - 1)
            
        case .monthly:
            let months = calendar.dateComponents([.month], from: lastEndDate, to: currentDate).month ?? 0
            return max(0, months - 1)
        }
    }
} 