import XCTest
@testable import ZmanimKit

final class SolarCalculatorTests: XCTestCase {

    private func date(_ year: Int, _ month: Int, _ day: Int, tz: TimeZone) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        return cal.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func timeString(_ date: Date?, tz: TimeZone) -> String {
        guard let date else { return "nil" }
        let f = DateFormatter()
        f.timeZone = tz
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    // MARK: - Jerusalem

    func testJerusalemSunrise() {
        let tz = TimeZone(identifier: "Asia/Jerusalem")!
        let solar = SolarCalculator(latitude: 31.7683, longitude: 35.2137, timeZone: tz)
        let d = date(2026, 3, 21, tz: tz) // Spring equinox
        let times = solar.times(for: d)
        XCTAssertNotNil(times.sunrise)
        XCTAssertNotNil(times.sunset)
        // Spring equinox sunrise ~05:40-05:50 IST, sunset ~17:45-17:55
        let riseStr = timeString(times.sunrise, tz: tz)
        XCTAssertTrue(riseStr >= "05:30" && riseStr <= "06:00",
                       "Jerusalem equinox sunrise expected ~05:45, got \(riseStr)")
        let setStr = timeString(times.sunset, tz: tz)
        XCTAssertTrue(setStr >= "17:35" && setStr <= "18:05",
                       "Jerusalem equinox sunset expected ~17:50, got \(setStr)")
    }

    func testJerusalemWinterSolstice() {
        let tz = TimeZone(identifier: "Asia/Jerusalem")!
        let solar = SolarCalculator(latitude: 31.7683, longitude: 35.2137, timeZone: tz)
        let d = date(2026, 12, 21, tz: tz)
        let times = solar.times(for: d)
        let riseStr = timeString(times.sunrise, tz: tz)
        // Winter solstice sunrise ~06:30 IST
        XCTAssertTrue(riseStr >= "06:20" && riseStr <= "06:45",
                       "Jerusalem winter sunrise expected ~06:33, got \(riseStr)")
    }

    // MARK: - New York

    func testNewYorkSummer() {
        let tz = TimeZone(identifier: "America/New_York")!
        let solar = SolarCalculator(latitude: 40.7128, longitude: -74.0060, timeZone: tz)
        let d = date(2026, 6, 21, tz: tz) // Summer solstice
        let times = solar.times(for: d)
        let riseStr = timeString(times.sunrise, tz: tz)
        let setStr = timeString(times.sunset, tz: tz)
        // NYC summer solstice: sunrise ~05:25 EDT, sunset ~20:30 EDT
        XCTAssertTrue(riseStr >= "05:15" && riseStr <= "05:40",
                       "NYC summer sunrise expected ~05:25, got \(riseStr)")
        XCTAssertTrue(setStr >= "20:20" && setStr <= "20:40",
                       "NYC summer sunset expected ~20:31, got \(setStr)")
    }

    // MARK: - Melbourne (Southern hemisphere)

    func testMelbourneSouthern() {
        let tz = TimeZone(identifier: "Australia/Melbourne")!
        let solar = SolarCalculator(latitude: -37.8136, longitude: 144.9631, timeZone: tz)
        let d = date(2026, 6, 21, tz: tz) // Winter solstice in southern hemisphere
        let times = solar.times(for: d)
        let riseStr = timeString(times.sunrise, tz: tz)
        let setStr = timeString(times.sunset, tz: tz)
        // Melbourne winter: sunrise ~07:35, sunset ~17:08 AEST
        XCTAssertTrue(riseStr >= "07:20" && riseStr <= "07:50",
                       "Melbourne winter sunrise expected ~07:35, got \(riseStr)")
        XCTAssertTrue(setStr >= "17:00" && setStr <= "17:20",
                       "Melbourne winter sunset expected ~17:08, got \(setStr)")
    }

    // MARK: - Polar edge case (Tromsø)

    func testTromsoMidnightSun() {
        let tz = TimeZone(identifier: "Europe/Oslo")!
        let solar = SolarCalculator(latitude: 69.6492, longitude: 18.9553, timeZone: tz)
        let d = date(2026, 6, 21, tz: tz) // Midnight sun
        let times = solar.times(for: d)
        // At 69.6°N in June, sun doesn't set
        XCTAssertNil(times.sunrise, "Tromsø midnight sun: no distinct sunrise")
        XCTAssertNil(times.sunset, "Tromsø midnight sun: no distinct sunset")
        XCTAssertNotNil(times.solarNoon, "Solar noon should still be available")
    }

    func testTromsoPolarNight() {
        let tz = TimeZone(identifier: "Europe/Oslo")!
        let solar = SolarCalculator(latitude: 69.6492, longitude: 18.9553, timeZone: tz)
        let d = date(2026, 12, 21, tz: tz) // Polar night
        let times = solar.times(for: d)
        XCTAssertNil(times.sunrise, "Tromsø polar night: no sunrise")
        XCTAssertNil(times.sunset, "Tromsø polar night: no sunset")
    }

    // MARK: - Day length symmetry

    func testEquinoxDayLength() {
        let tz = TimeZone(identifier: "America/New_York")!
        let solar = SolarCalculator(latitude: 40.7128, longitude: -74.0060, timeZone: tz)
        let d = date(2026, 3, 20, tz: tz)
        let times = solar.times(for: d)
        guard let rise = times.sunrise, let set = times.sunset else {
            XCTFail("Should have sunrise/sunset at equinox")
            return
        }
        let dayLengthHours = set.timeIntervalSince(rise) / 3600
        // Equinox day length should be ~12 hours (±0.25h due to refraction)
        XCTAssertTrue(dayLengthHours > 11.75 && dayLengthHours < 12.35,
                       "Equinox day length expected ~12h, got \(dayLengthHours)")
    }

    // MARK: - Sun angle times

    func testDawnAngle() {
        let tz = TimeZone(identifier: "Asia/Jerusalem")!
        let solar = SolarCalculator(latitude: 31.7683, longitude: 35.2137, timeZone: tz)
        let d = date(2026, 3, 21, tz: tz)
        let dawn = solar.sunAngleTime(for: d, angle: 16.1, rising: true)
        let sunrise = solar.times(for: d).sunrise
        XCTAssertNotNil(dawn)
        XCTAssertNotNil(sunrise)
        if let dawn, let sunrise {
            XCTAssertTrue(dawn < sunrise, "Dawn must be before sunrise")
            let diff = sunrise.timeIntervalSince(dawn) / 60
            // Dawn at 16.1° should be ~70-80 minutes before sunrise at this latitude/date
            XCTAssertTrue(diff > 50 && diff < 100,
                           "Dawn-sunrise gap expected 60-90 min, got \(diff)")
        }
    }

    func testNightfallAngle() {
        let tz = TimeZone(identifier: "America/New_York")!
        let solar = SolarCalculator(latitude: 40.7128, longitude: -74.0060, timeZone: tz)
        let d = date(2026, 6, 21, tz: tz)
        let nightfall = solar.sunAngleTime(for: d, angle: 8.5, rising: false)
        let sunset = solar.times(for: d).sunset
        XCTAssertNotNil(nightfall)
        XCTAssertNotNil(sunset)
        if let nightfall, let sunset {
            XCTAssertTrue(nightfall > sunset, "Nightfall must be after sunset")
            let diff = nightfall.timeIntervalSince(sunset) / 60
            // 8.5° nightfall should be ~35-50 minutes after sunset in summer NYC
            XCTAssertTrue(diff > 25 && diff < 65,
                           "Sunset-nightfall gap expected 30-55 min, got \(diff)")
        }
    }
}
