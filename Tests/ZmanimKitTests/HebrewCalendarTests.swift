import XCTest
@testable import ZmanimKit

final class HebrewCalendarTests: XCTestCase {

    private func gregorianDate(
        _ year: Int, _ month: Int, _ day: Int, tz: TimeZone = .gmt
    ) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        return cal.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func hebrewDate(
        _ year: Int, _ month: Int, _ day: Int, tz: TimeZone = .gmt
    ) -> Date {
        var cal = Calendar(identifier: .hebrew)
        cal.timeZone = tz
        return cal.date(from: DateComponents(year: year, month: month, day: day))!
    }

    // MARK: - Date conversion

    func testKnownDate() {
        // 1 Tishrei 5787 = September 12, 2026 (Gregorian)
        let d = gregorianDate(2026, 9, 12)
        let hd = HebrewDate(from: d, timeZone: .gmt)
        XCTAssertEqual(hd.year, 5787)
        XCTAssertEqual(hd.month, 1)
        XCTAssertEqual(hd.day, 1)
    }

    func testMonthName() {
        let d = gregorianDate(2026, 9, 12)
        let hd = HebrewDate(from: d, timeZone: .gmt)
        XCTAssertEqual(hd.monthName, "Tishrei")
    }

    func testLeapYear() {
        // 5787 (2026-27): 5787 % 19 = 11 → IS in [0,3,6,8,11,14,17] → leap year
        let d = gregorianDate(2026, 9, 12)
        let hd = HebrewDate(from: d, timeZone: .gmt)
        XCTAssertTrue(hd.isLeapYear)
    }

    func testLeapYearTrue() {
        // 5784 (2023-24): 5784 % 19 = 6 → IS a leap year
        let d = gregorianDate(2024, 3, 15)
        let hd = HebrewDate(from: d, timeZone: .gmt)
        XCTAssertEqual(hd.year, 5784)
        XCTAssertTrue(hd.isLeapYear)
    }

    // MARK: - Formatting

    func testFormattedDate() {
        let hd = HebrewDate(year: 5787, month: 1, day: 15)
        XCTAssertEqual(hd.formatted, "15 Tishrei 5787")
    }

    // MARK: - Hebrew numerals

    func testHebrewDay15() {
        XCTAssertEqual(HebrewNumerals.dayString(15), "ט״ו")
    }

    func testHebrewDay16() {
        XCTAssertEqual(HebrewNumerals.dayString(16), "ט״ז")
    }

    func testHebrewDay1() {
        XCTAssertEqual(HebrewNumerals.dayString(1), "א׳")
    }

    func testHebrewDay10() {
        XCTAssertEqual(HebrewNumerals.dayString(10), "י׳")
    }

    func testHebrewDay25() {
        XCTAssertEqual(HebrewNumerals.dayString(25), "כ״ה")
    }

    // MARK: - Round-trip conversion

    func testGregorianRoundTrip() {
        let original = gregorianDate(2026, 10, 22)
        let hd = HebrewDate(from: original, timeZone: .gmt)
        guard let back = hd.toGregorianDate() else {
            XCTFail("Round-trip conversion failed")
            return
        }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .gmt
        XCTAssertTrue(cal.isDate(original, inSameDayAs: back))
    }

    // MARK: - Sunset boundary

    func testReligiousDateBeforeSunset() {
        let tz = TimeZone(identifier: "Asia/Jerusalem")!
        let noon = gregorianDate(2026, 10, 22, tz: tz)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let sunset = cal.date(bySettingHour: 17, minute: 30, second: 0, of: noon)!

        let hd = HebrewDate.religiousDate(at: noon, sunset: sunset, timeZone: tz)
        let plain = HebrewDate(from: noon, timeZone: tz)
        XCTAssertEqual(hd.day, plain.day, "Before sunset should be same day")
    }

    func testReligiousDateAfterSunset() {
        let tz = TimeZone(identifier: "Asia/Jerusalem")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let base = gregorianDate(2026, 10, 22, tz: tz)
        let sunset = cal.date(bySettingHour: 17, minute: 30, second: 0, of: base)!
        let evening = cal.date(bySettingHour: 19, minute: 0, second: 0, of: base)!

        let hd = HebrewDate.religiousDate(at: evening, sunset: sunset, timeZone: tz)
        let plain = HebrewDate(from: base, timeZone: tz)
        XCTAssertEqual(hd.day, plain.day + 1,
                       "After sunset should advance to next Hebrew day")
    }
}
