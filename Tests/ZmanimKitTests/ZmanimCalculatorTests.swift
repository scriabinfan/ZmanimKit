import XCTest
@testable import ZmanimKit

final class ZmanimCalculatorTests: XCTestCase {

    private let jerusalemTZ = TimeZone(identifier: "Asia/Jerusalem")!
    private let nyTZ = TimeZone(identifier: "America/New_York")!

    private func date(_ year: Int, _ month: Int, _ day: Int, tz: TimeZone) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        return cal.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func timeStr(_ date: Date?, tz: TimeZone) -> String {
        guard let date else { return "nil" }
        let f = DateFormatter()
        f.timeZone = tz
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    // MARK: - GRA Method

    func testGRAZmanimJerusalem() {
        let calc = ZmanimCalculator(
            latitude: 31.7683, longitude: 35.2137, timeZone: jerusalemTZ
        )
        let d = date(2026, 3, 21, tz: jerusalemTZ)
        let z = calc.zmanim(for: d, method: .gra)

        XCTAssertNotNil(z.sunrise)
        XCTAssertNotNil(z.sunset)
        XCTAssertNotNil(z.latestShema)
        XCTAssertNotNil(z.latestShacharit)
        XCTAssertNotNil(z.chatzot)
        XCTAssertNotNil(z.minchaGedola)
        XCTAssertNotNil(z.plagHaMincha)
        XCTAssertNotNil(z.nightfall)

        // Verify chronological order
        if let shema = z.latestShema, let tefilla = z.latestShacharit,
           let noon = z.chatzot, let mg = z.minchaGedola,
           let mk = z.minchaKetana, let plag = z.plagHaMincha {
            XCTAssertTrue(shema < tefilla)
            XCTAssertTrue(tefilla < noon)
            XCTAssertTrue(noon < mg)
            XCTAssertTrue(mg < mk)
            XCTAssertTrue(mk < plag)
        }

        // GRA latest Shema should be ~3h after sunrise (~08:45)
        let shemaStr = timeStr(z.latestShema, tz: jerusalemTZ)
        XCTAssertTrue(shemaStr >= "08:30" && shemaStr <= "09:10",
                       "GRA Shema expected ~08:50, got \(shemaStr)")
    }

    // MARK: - MGA Method

    func testMGA72LatestShema() {
        let calc = ZmanimCalculator(
            latitude: 40.7128, longitude: -74.0060, timeZone: nyTZ
        )
        let d = date(2026, 3, 21, tz: nyTZ)
        let gra = calc.zmanim(for: d, method: .gra)
        let mga = calc.zmanim(for: d, method: .mga72)

        // MGA Shema should be earlier than GRA (wider day boundaries)
        if let graShema = gra.latestShema, let mgaShema = mga.latestShema {
            XCTAssertTrue(mgaShema < graShema,
                           "MGA Shema must be earlier than GRA")
        }
    }

    // MARK: - Entries

    func testEntriesSorted() {
        let calc = ZmanimCalculator(
            latitude: 31.7683, longitude: 35.2137, timeZone: jerusalemTZ
        )
        let z = calc.zmanim(for: date(2026, 6, 15, tz: jerusalemTZ))
        let entries = z.entries
        for i in 1..<entries.count {
            XCTAssertTrue(entries[i].time >= entries[i - 1].time,
                           "Entries must be sorted chronologically")
        }
    }

    // MARK: - Candle lighting

    func testCandleLighting18Min() {
        let calc = ZmanimCalculator(
            latitude: 31.7683, longitude: 35.2137, timeZone: jerusalemTZ
        )
        let d = date(2026, 10, 9, tz: jerusalemTZ) // Friday
        let candles = calc.candleLighting(for: d, minutesBefore: 18)
        let sunset = calc.solar.times(for: d).sunset
        XCTAssertNotNil(candles)
        XCTAssertNotNil(sunset)
        if let candles, let sunset {
            let diff = sunset.timeIntervalSince(candles)
            XCTAssertEqual(diff, 18 * 60, accuracy: 1)
        }
    }

    func testCandleLighting40MinJerusalem() {
        let calc = ZmanimCalculator(
            latitude: 31.7683, longitude: 35.2137, timeZone: jerusalemTZ
        )
        let d = date(2026, 10, 9, tz: jerusalemTZ)
        let candles = calc.candleLighting(for: d, minutesBefore: 40)
        let sunset = calc.solar.times(for: d).sunset
        if let candles, let sunset {
            let diff = sunset.timeIntervalSince(candles)
            XCTAssertEqual(diff, 40 * 60, accuracy: 1)
        }
    }

    // MARK: - Fixed-minute nightfall

    func testFixedMinuteNightfall() {
        let calc = ZmanimCalculator(
            latitude: 40.7128, longitude: -74.0060, timeZone: nyTZ
        )
        let d = date(2026, 3, 21, tz: nyTZ)
        let n72 = calc.fixedMinuteNightfall(for: d, minutes: 72)
        let sunset = calc.solar.times(for: d).sunset
        if let n72, let sunset {
            let diff = n72.timeIntervalSince(sunset)
            XCTAssertEqual(diff, 72 * 60, accuracy: 1)
        }
    }

    // MARK: - Chatzot Layla

    func testChatzotNight() {
        let calc = ZmanimCalculator(
            latitude: 31.7683, longitude: 35.2137, timeZone: jerusalemTZ
        )
        let d = date(2026, 3, 21, tz: jerusalemTZ)
        let midnight = calc.chatzotNight(for: d)
        XCTAssertNotNil(midnight)
        if let midnight {
            let f = DateFormatter()
            f.timeZone = jerusalemTZ
            f.dateFormat = "HH:mm"
            let str = f.string(from: midnight)
            // Halachic midnight around equinox should be ~23:45-00:15
            XCTAssertTrue(str >= "23:30" || str <= "00:30",
                           "Chatzot night expected ~midnight, got \(str)")
        }
    }

    // MARK: - Unavailable at polar latitudes

    func testPolarUnavailable() {
        let tz = TimeZone(identifier: "Europe/Oslo")!
        let calc = ZmanimCalculator(latitude: 69.6492, longitude: 18.9553, timeZone: tz)
        let d = date(2026, 6, 21, tz: tz) // Midnight sun
        let z = calc.zmanim(for: d)
        XCTAssertFalse(z.unavailable.isEmpty, "Should have unavailable zmanim at polar latitude")
        XCTAssertTrue(z.unavailable.contains("Sunrise"))
    }

    // MARK: - All methods produce results

    func testAllMethodsProduce() {
        let calc = ZmanimCalculator(
            latitude: 40.7128, longitude: -74.0060, timeZone: nyTZ
        )
        let d = date(2026, 6, 15, tz: nyTZ)
        for method in ZmanimMethod.allCases {
            let z = calc.zmanim(for: d, method: method)
            XCTAssertNotNil(z.sunrise, "\(method) should have sunrise")
            XCTAssertNotNil(z.latestShema, "\(method) should have latest shema")
            XCTAssertTrue(z.availableCount >= 10,
                           "\(method) should produce at least 10 zmanim")
        }
    }
}
