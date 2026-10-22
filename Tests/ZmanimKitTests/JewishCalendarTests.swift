import XCTest
@testable import ZmanimKit

final class JewishCalendarTests: XCTestCase {

    private func jewishDay(
        year: Int, month: Int, day: Int, weekday: Int = 0, israel: Bool = false
    ) -> JewishDay {
        let hd = HebrewDate(year: year, month: month, day: day)
        return JewishDay(hebrewDate: hd, israel: israel)
    }

    private func dayFromGregorian(
        _ year: Int, _ month: Int, _ day: Int,
        israel: Bool = false, tz: TimeZone = .gmt
    ) -> JewishDay {
        let date = gregorianDate(year, month, day, tz: tz)
        return JewishDay(from: date, timeZone: tz, israel: israel)
    }

    private func gregorianDate(
        _ year: Int, _ month: Int, _ day: Int, tz: TimeZone = .gmt
    ) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        return cal.date(from: DateComponents(year: year, month: month, day: day))!
    }

    // MARK: - Chanukah detection

    func testChanukahStart() {
        // 25 Kislev 5787
        var cal = Calendar(identifier: .hebrew)
        cal.timeZone = .gmt
        let d = cal.date(from: DateComponents(year: 5787, month: 3, day: 25))!
        let jd = JewishDay(from: d, timeZone: .gmt, israel: false)
        XCTAssertTrue(jd.isChanukah)
        XCTAssertTrue(jd.occasions.contains(.chanukah))
    }

    func testNotChanukah() {
        let jd = dayFromGregorian(2026, 9, 15) // Tishrei
        XCTAssertFalse(jd.isChanukah)
    }

    // MARK: - Rosh Hashanah

    func testRoshHashanah() {
        // 1 Tishrei 5787 = Sept 12, 2026
        let jd = dayFromGregorian(2026, 9, 12)
        XCTAssertTrue(jd.isRoshHashanah)
        XCTAssertTrue(jd.isTenDays)
        XCTAssertTrue(jd.occasions.contains(.roshHashanah))
        XCTAssertTrue(jd.occasions.contains(.tenDays))
    }

    // MARK: - Yom Kippur

    func testYomKippur() {
        // 10 Tishrei 5787 = Sept 21, 2026
        let jd = dayFromGregorian(2026, 9, 21)
        XCTAssertTrue(jd.isYomKippur)
        XCTAssertTrue(jd.isTenDays)
    }

    // MARK: - Israel/Diaspora divergence

    func testPesachIsrael() {
        // 15 Nisan is Yom Tov in both, 16 Nisan is CHM in Israel, YT in Diaspora
        // 5787 is a leap year, so Nisan = month 8
        var cal = Calendar(identifier: .hebrew)
        cal.timeZone = .gmt
        let nisan16 = cal.date(from: DateComponents(year: 5787, month: 8, day: 16))!

        let israelDay = JewishDay(from: nisan16, timeZone: .gmt, israel: true)
        let diasporaDay = JewishDay(from: nisan16, timeZone: .gmt, israel: false)

        XCTAssertTrue(israelDay.isCholHamoedPesach, "16 Nisan is CHM Pesach in Israel")
        XCTAssertTrue(diasporaDay.isPesach, "16 Nisan is YT Pesach in Diaspora")
    }

    func testShavuotIsrael() {
        // 5787 is a leap year, so Sivan = month 10
        var cal = Calendar(identifier: .hebrew)
        cal.timeZone = .gmt
        let sivan7 = cal.date(from: DateComponents(year: 5787, month: 10, day: 7))!

        let israelDay = JewishDay(from: sivan7, timeZone: .gmt, israel: true)
        let diasporaDay = JewishDay(from: sivan7, timeZone: .gmt, israel: false)

        XCTAssertFalse(israelDay.isShavuot, "7 Sivan is not Shavuot in Israel")
        XCTAssertTrue(diasporaDay.isShavuot, "7 Sivan is Shavuot II in Diaspora")
    }

    // MARK: - Minor fast postponement

    func testTzomGedaliah() {
        // 3 Tishrei 5787 = Sept 14, 2026 (Monday) — should be the fast
        let jd = dayFromGregorian(2026, 9, 14)
        XCTAssertNotNil(jd.minorFast)
        if let fast = jd.minorFast {
            XCTAssertEqual(fast, .tzomGedaliah)
        }
    }

    // MARK: - Rosh Chodesh

    func testRoshChodesh() {
        var cal = Calendar(identifier: .hebrew)
        cal.timeZone = .gmt
        let cheshvan1 = cal.date(from: DateComponents(year: 5787, month: 2, day: 1))!
        let jd = JewishDay(from: cheshvan1, timeZone: .gmt, israel: false)
        XCTAssertTrue(jd.isRoshChodesh)
        XCTAssertTrue(jd.occasions.contains(.roshChodesh))
    }

    func testTishrei1NotRoshChodesh() {
        // 1 Tishrei is Rosh Hashanah, not labeled Rosh Chodesh
        let jd = dayFromGregorian(2026, 9, 12)
        XCTAssertFalse(jd.isRoshChodesh)
    }

    // MARK: - Hallel

    func testFullHallelChanukah() {
        var cal = Calendar(identifier: .hebrew)
        cal.timeZone = .gmt
        let d = cal.date(from: DateComponents(year: 5787, month: 3, day: 25))!
        let jd = JewishDay(from: d, timeZone: .gmt, israel: false)
        XCTAssertEqual(jd.hallelType, .full)
    }

    func testPartialHallelRoshChodesh() {
        var cal = Calendar(identifier: .hebrew)
        cal.timeZone = .gmt
        let d = cal.date(from: DateComponents(year: 5787, month: 2, day: 1))!
        let jd = JewishDay(from: d, timeZone: .gmt, israel: false)
        XCTAssertEqual(jd.hallelType, .partial)
    }

    // MARK: - Rain

    func testRainMentionTishrei() {
        var cal = Calendar(identifier: .hebrew)
        cal.timeZone = .gmt
        let d = cal.date(from: DateComponents(year: 5787, month: 1, day: 22))!
        let jd = JewishDay(from: d, timeZone: .gmt, israel: false)
        XCTAssertTrue(jd.hasRainMention,
                       "Rain mention starts from 22 Tishrei (Shemini Atzeret)")
    }

    func testNoRainMentionSummer() {
        var cal = Calendar(identifier: .hebrew)
        cal.timeZone = .gmt
        let d = cal.date(from: DateComponents(year: 5787, month: 9, day: 15))!
        let jd = JewishDay(from: d, timeZone: .gmt, israel: false)
        XCTAssertFalse(jd.hasRainMention)
    }

    func testRainRequestIsrael() {
        var cal = Calendar(identifier: .hebrew)
        cal.timeZone = .gmt
        let d = cal.date(from: DateComponents(year: 5787, month: 2, day: 7))!
        let jd = JewishDay(from: d, timeZone: .gmt, israel: true)
        XCTAssertTrue(jd.hasRainRequest,
                       "Israel rain request starts 7 Cheshvan")
    }

    // MARK: - Annual holidays

    func testAnnualHolidayCount() {
        let holidays = JewishHolidays.holidays(year: 5787, israel: false)
        XCTAssertTrue(holidays.count > 20,
                       "Should generate at least 20 holidays, got \(holidays.count)")
    }

    func testAnnualHolidayIsrael() {
        let israelHolidays = JewishHolidays.holidays(year: 5787, israel: true)
        let diasporaHolidays = JewishHolidays.holidays(year: 5787, israel: false)
        XCTAssertTrue(diasporaHolidays.count > israelHolidays.count,
                       "Diaspora should have more holidays (extra days)")
    }

    // MARK: - Occasion set completeness

    func testOccasionSetShabbatChanukah() {
        var cal = Calendar(identifier: .hebrew)
        cal.timeZone = .gmt
        // Find a Shabbat during Chanukah — check each day
        for day in 25...30 {
            let d = cal.date(from: DateComponents(year: 5787, month: 3, day: day))!
            let jd = JewishDay(from: d, timeZone: .gmt, israel: false)
            if jd.isShabbat && jd.isChanukah {
                let occ = jd.occasions
                XCTAssertTrue(occ.contains(.shabbat))
                XCTAssertTrue(occ.contains(.chanukah))
                return
            }
        }
        // Not all years have Shabbat Chanukah on these specific days
    }

    // MARK: - Summary labels

    func testSummaryLabels() {
        let jd = dayFromGregorian(2026, 9, 12) // Rosh Hashanah
        let labels = jd.summary
        XCTAssertTrue(labels.contains("Rosh Hashanah"))
    }
}
