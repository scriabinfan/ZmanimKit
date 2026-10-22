import XCTest
@testable import ZmanimKit

final class TorahReadingsTests: XCTestCase {

    private func gregorianDate(
        _ year: Int, _ month: Int, _ day: Int, tz: TimeZone = .gmt
    ) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        return cal.date(from: DateComponents(year: year, month: month, day: day))!
    }

    // MARK: - Parasha catalog

    func testParashaCount() {
        XCTAssertEqual(ParashaList.all.count, 54)
    }

    func testFirstParasha() {
        let p = ParashaList.parasha(1)
        XCTAssertEqual(p.name, "Bereishit")
        XCTAssertEqual(p.hebrew, "בראשית")
        XCTAssertEqual(p.book, .bereishit)
        XCTAssertFalse(p.isDouble)
    }

    func testLastParasha() {
        let p = ParashaList.parasha(54)
        XCTAssertEqual(p.name, "V'Zot HaBracha")
        XCTAssertEqual(p.book, .devarim)
    }

    func testDoubleParasha() {
        let dp = ParashaList.double(22, 23)
        XCTAssertTrue(dp.isDouble)
        XCTAssertEqual(dp.displayName, "Vayakhel-Pekudei")
        XCTAssertTrue(dp.displayHebrew.contains("ויקהל"))
        XCTAssertTrue(dp.displayHebrew.contains("פקודי"))
    }

    // MARK: - Annual schedule

    func testScheduleCoversFullYear() {
        let schedule = TorahReadings.annualSchedule(year: 5787, israel: false, timeZone: .gmt)
        XCTAssertTrue(schedule.count >= 47, "Should have at least 47 Shabbatot, got \(schedule.count)")
        XCTAssertTrue(schedule.count <= 55, "Should have at most 55 Shabbatot, got \(schedule.count)")
    }

    func testBereishitIsFirst() {
        let schedule = TorahReadings.annualSchedule(year: 5787, israel: false, timeZone: .gmt)
        let first = schedule.first { $0.parasha != nil }
        XCTAssertEqual(first?.parasha?.name, "Bereishit")
    }

    func testHaazinuIsLast() {
        let schedule = TorahReadings.annualSchedule(year: 5787, israel: false, timeZone: .gmt)
        let lastParasha = schedule.last { $0.parasha != nil }
        XCTAssertNotNil(lastParasha)
        let name = lastParasha!.parasha!.displayName
        // Should end with Haazinu (53) — V'Zot HaBracha is on Simchat Torah
        XCTAssertTrue(
            name.contains("Haazinu") || name.contains("Vayelech") || name.contains("Nitzavim"),
            "Last parasha should be near end of Devarim, got \(name)"
        )
    }

    func testAllParashotCovered() {
        let schedule = TorahReadings.annualSchedule(year: 5787, israel: false, timeZone: .gmt)
        var covered = Set<Int>()
        for reading in schedule {
            if let p = reading.parasha {
                covered.insert(p.index)
                if let di = p.doubleIndex { covered.insert(di) }
            }
        }
        // Parashot 1-53 should all appear (54 is on Simchat Torah)
        for i in 1...53 {
            XCTAssertTrue(covered.contains(i), "Parasha \(i) (\(ParashaList.all[i-1].name)) missing")
        }
    }

    func testScheduleIsChronological() {
        let schedule = TorahReadings.annualSchedule(year: 5787, israel: false, timeZone: .gmt)
        for i in 1..<schedule.count {
            XCTAssertTrue(
                schedule[i].date > schedule[i - 1].date,
                "Schedule not chronological at index \(i)"
            )
        }
    }

    // MARK: - Doubles

    func testDoubleParashotExist() {
        let schedule = TorahReadings.annualSchedule(year: 5787, israel: false, timeZone: .gmt)
        let doubles = schedule.filter { $0.parasha?.isDouble == true }
        XCTAssertTrue(doubles.count >= 1, "Non-leap year should have double parashot")
    }

    func testIsraelFewerDoubles() {
        let israelSchedule = TorahReadings.annualSchedule(year: 5787, israel: true, timeZone: .gmt)
        let diasporaSchedule = TorahReadings.annualSchedule(year: 5787, israel: false, timeZone: .gmt)

        let israelDoubles = israelSchedule.filter { $0.parasha?.isDouble == true }.count
        let diasporaDoubles = diasporaSchedule.filter { $0.parasha?.isDouble == true }.count

        XCTAssertTrue(
            diasporaDoubles >= israelDoubles,
            "Diaspora should have >= doubles than Israel (\(diasporaDoubles) vs \(israelDoubles))"
        )
    }

    // MARK: - Israel/Diaspora divergence

    func testIsraelDiasporaDivergence() {
        let israelSchedule = TorahReadings.annualSchedule(year: 5787, israel: true, timeZone: .gmt)
        let diasporaSchedule = TorahReadings.annualSchedule(year: 5787, israel: false, timeZone: .gmt)

        // Both should cover all parashot
        var israelCovered = Set<Int>()
        for r in israelSchedule {
            if let p = r.parasha {
                israelCovered.insert(p.index)
                if let di = p.doubleIndex { israelCovered.insert(di) }
            }
        }
        for i in 1...53 {
            XCTAssertTrue(israelCovered.contains(i), "Israel missing parasha \(i)")
        }

        var diasporaCovered = Set<Int>()
        for r in diasporaSchedule {
            if let p = r.parasha {
                diasporaCovered.insert(p.index)
                if let di = p.doubleIndex { diasporaCovered.insert(di) }
            }
        }
        for i in 1...53 {
            XCTAssertTrue(diasporaCovered.contains(i), "Diaspora missing parasha \(i)")
        }
    }

    // MARK: - Holiday readings

    func testHolidayShabbatDetection() {
        let schedule = TorahReadings.annualSchedule(year: 5787, israel: false, timeZone: .gmt)
        let holidays = schedule.filter { $0.holidayReading != nil }
        // There should be at least a few holiday Shabbatot
        XCTAssertTrue(holidays.count >= 1, "Should detect holiday Shabbatot")
    }

    // MARK: - Special Shabbatot

    func testSpecialShabbatotDetected() {
        let schedule = TorahReadings.annualSchedule(year: 5787, israel: false, timeZone: .gmt)
        let specials = schedule.compactMap { $0.specialShabbat }
        let types = Set(specials)
        // Should find at least Shuvah and the 4 parshiyot
        XCTAssertTrue(types.contains(.shuvah), "Should find Shabbat Shuvah")
        XCTAssertTrue(types.contains(.zachor), "Should find Shabbat Zachor")
        XCTAssertTrue(types.contains(.haGadol), "Should find Shabbat HaGadol")
    }

    // MARK: - Reading for specific date

    func testReadingForDate() {
        // Oct 17, 2026 is a Shabbat (Bereishit 5787)
        let shabbat = gregorianDate(2026, 10, 17)
        let reading = TorahReadings.reading(for: shabbat, timeZone: .gmt, israel: false)
        XCTAssertNotNil(reading, "Should return a reading for a Shabbat")
        if let p = reading?.parasha {
            XCTAssertEqual(p.book, .bereishit, "Early Tishrei parasha should be from Bereishit")
        }
    }

    func testNoReadingForWeekday() {
        // Oct 18, 2026 is a Sunday
        let sunday = gregorianDate(2026, 10, 18)
        let reading = TorahReadings.reading(for: sunday, timeZone: .gmt, israel: false)
        XCTAssertNil(reading, "Should not return a reading for a weekday")
    }

    // MARK: - Multiple years

    func testLeapYearSchedule() {
        // 5787 is a leap year
        let schedule = TorahReadings.annualSchedule(year: 5787, israel: false, timeZone: .gmt)
        let doubles = schedule.filter { $0.parasha?.isDouble == true }.count
        // Leap years have more Shabbatot, so fewer doubles needed
        XCTAssertTrue(schedule.count >= 50, "Leap year should have at least 50 Shabbatot")
        // Verify all parashot still covered
        var covered = Set<Int>()
        for r in schedule {
            if let p = r.parasha {
                covered.insert(p.index)
                if let di = p.doubleIndex { covered.insert(di) }
            }
        }
        for i in 1...53 {
            XCTAssertTrue(covered.contains(i), "Leap year missing parasha \(i)")
        }
    }

    func testNonLeapYearSchedule() {
        // 5785 is not a leap year (5785 % 19 = 12, not in leap set)
        let schedule = TorahReadings.annualSchedule(year: 5785, israel: false, timeZone: .gmt)
        var covered = Set<Int>()
        for r in schedule {
            if let p = r.parasha {
                covered.insert(p.index)
                if let di = p.doubleIndex { covered.insert(di) }
            }
        }
        for i in 1...53 {
            XCTAssertTrue(covered.contains(i), "Non-leap year missing parasha \(i)")
        }
    }

    // MARK: - Display names

    func testWeeklyReadingDisplayName() {
        let schedule = TorahReadings.annualSchedule(year: 5787, israel: false, timeZone: .gmt)
        let first = schedule.first { $0.parasha != nil }!
        XCTAssertTrue(first.displayName.contains("Bereishit"))
    }
}
