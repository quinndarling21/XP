import Foundation

extension Date {
    static var now: Date {
        print("Date.now called")
        
        if let dateString = ProcessInfo.processInfo.environment["RESET_TESTING_DATE"] {
            print(" Environment variable found: \(dateString)")
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [
                .withFullDate,
                .withFullTime,
                .withDashSeparatorInDate,
                .withColonSeparatorInTime,
                .withTimeZone
            ]
            
            if let date = formatter.date(from: dateString) {
                print("✅ Successfully parsed date: \(date)")
                return date
            } else {
                print("❌ Failed to parse date string: \(dateString)")
                print("⚠️ Falling back to current date")
                return Date()
            }
        }
        
        print("⚠️ No test date set, using current date")
        return Date()
    }
} 