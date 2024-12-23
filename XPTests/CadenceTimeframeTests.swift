import XCTest
@testable import XP

final class CadenceTimeframeTests: XCTestCase {
    let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withFullTime, .withTimeZone]
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    // MARK: - Next Start Date Tests
    
    func testNextStartDateDaily() {
        // Given a date at any time
        let currentDate = dateFormatter.date(from: "2024-01-15T15:30:00-08:00")!
        
        // When we calculate next start date for daily cadence
        let nextStart = CadenceTimeframe.nextStartDate(after: currentDate, frequency: .daily)
        
        // Then it should be midnight of the next day
        XCTAssertEqual(
            dateFormatter.string(from: nextStart),
            "2024-01-16T00:00:00-08:00"
        )
    }
    
    func testNextStartDateWeekly() {
        // Given a date mid-week (Wednesday)
        let currentDate = dateFormatter.date(from: "2024-01-17T15:30:00-08:00")!
        
        // When we calculate next start date for weekly cadence
        let nextStart = CadenceTimeframe.nextStartDate(after: currentDate, frequency: .weekly)
        
        // Then it should be midnight next Monday
        XCTAssertEqual(
            dateFormatter.string(from: nextStart),
            "2024-01-22T00:00:00-08:00"
        )
    }
    
    func testNextStartDateMonthly() {
        // Given a date mid-month
        let currentDate = dateFormatter.date(from: "2024-01-15T15:30:00-08:00")!
        
        // When we calculate next start date for monthly cadence
        let nextStart = CadenceTimeframe.nextStartDate(after: currentDate, frequency: .monthly)
        
        // Then it should be midnight on the first of next month
        XCTAssertEqual(
            dateFormatter.string(from: nextStart),
            "2024-02-01T00:00:00-08:00"
        )
    }
    
    // MARK: - Calculate Start Date Tests
    
    func testCalculateStartDateDaily() {
        // Given a last end date and current date with gap
        let lastEndDate = dateFormatter.date(from: "2024-01-15T00:00:00-08:00")!
        let currentDate = dateFormatter.date(from: "2024-01-17T15:30:00-08:00")!
        
        // When we calculate the start date
        let startDate = CadenceTimeframe.calculateStartDate(
            from: lastEndDate,
            currentDate: currentDate,
            frequency: .daily
        )
        
        // Then it should be midnight of current day
        XCTAssertEqual(
            dateFormatter.string(from: startDate),
            "2024-01-17T00:00:00-08:00"
        )
    }
    
    func testCalculateStartDateWeekly() {
        // Given a last end date and current date with gap
        let lastEndDate = dateFormatter.date(from: "2024-01-08T00:00:00-08:00")! // Monday
        let currentDate = dateFormatter.date(from: "2024-01-17T15:30:00-08:00")! // Wednesday
        
        // When we calculate the start date
        let startDate = CadenceTimeframe.calculateStartDate(
            from: lastEndDate,
            currentDate: currentDate,
            frequency: .weekly
        )
        
        // Then it should be midnight of the most recent Monday
        XCTAssertEqual(
            dateFormatter.string(from: startDate),
            "2024-01-15T00:00:00-08:00"
        )
    }
    
    func testCalculateStartDateMonthly() {
        // Given a last end date and current date with gap
        let lastEndDate = dateFormatter.date(from: "2024-01-01T00:00:00-08:00")!
        let currentDate = dateFormatter.date(from: "2024-02-15T15:30:00-08:00")!
        
        // When we calculate the start date
        let startDate = CadenceTimeframe.calculateStartDate(
            from: lastEndDate,
            currentDate: currentDate,
            frequency: .monthly
        )
        
        // Then it should be midnight of the first of current month
        XCTAssertEqual(
            dateFormatter.string(from: startDate),
            "2024-02-01T00:00:00-08:00"
        )
    }
    
    // MARK: - Missed Cycles Tests
    
    func testMissedCyclesDaily() {
        // Given dates 3 days apart
        let lastEndDate = dateFormatter.date(from: "2024-01-15T00:00:00-08:00")!
        let currentDate = dateFormatter.date(from: "2024-01-18T15:30:00-08:00")!
        
        // When we calculate missed cycles
        let missed = CadenceTimeframe.missedCycles(
            between: lastEndDate,
            and: currentDate,
            frequency: .daily
        )
        
        // Then it should be 2 (16th and 17th were missed)
        XCTAssertEqual(missed, 2)
    }
    
    func testMissedCyclesWeekly() {
        // Given dates 3 weeks apart
        let lastEndDate = dateFormatter.date(from: "2024-01-01T00:00:00-08:00")! // Monday
        let currentDate = dateFormatter.date(from: "2024-01-22T15:30:00-08:00")! // Monday
        
        // When we calculate missed cycles
        let missed = CadenceTimeframe.missedCycles(
            between: lastEndDate,
            and: currentDate,
            frequency: .weekly
        )
        
        // Then it should be 2 (weeks of 8th and 15th were missed)
        XCTAssertEqual(missed, 2)
    }
    
    func testMissedCyclesMonthly() {
        // Given dates 3 months apart
        let lastEndDate = dateFormatter.date(from: "2024-01-01T00:00:00-08:00")!
        let currentDate = dateFormatter.date(from: "2024-03-15T15:30:00-08:00")!
        
        // When we calculate missed cycles
        let missed = CadenceTimeframe.missedCycles(
            between: lastEndDate,
            and: currentDate,
            frequency: .monthly
        )
        
        // Then it should be 1 (February was missed)
        XCTAssertEqual(missed, 1)
    }
    
    func testNoMissedCyclesWhenSameDay() {
        // Given dates on the same day
        let lastEndDate = dateFormatter.date(from: "2024-01-15T00:00:00-08:00")!
        let currentDate = dateFormatter.date(from: "2024-01-15T15:30:00-08:00")!
        
        // When we calculate missed cycles for all frequencies
        let missedDaily = CadenceTimeframe.missedCycles(
            between: lastEndDate,
            and: currentDate,
            frequency: .daily
        )
        let missedWeekly = CadenceTimeframe.missedCycles(
            between: lastEndDate,
            and: currentDate,
            frequency: .weekly
        )
        let missedMonthly = CadenceTimeframe.missedCycles(
            between: lastEndDate,
            and: currentDate,
            frequency: .monthly
        )
        
        // Then all should be 0
        XCTAssertEqual(missedDaily, 0)
        XCTAssertEqual(missedWeekly, 0)
        XCTAssertEqual(missedMonthly, 0)
    }
} 
