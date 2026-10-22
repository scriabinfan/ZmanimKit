import Foundation

/// Computes sunrise, sunset, and solar noon for any location and date
/// using the NOAA Solar Calculator algorithm (public domain).
///
/// Reference: https://gml.noaa.gov/grad/solcalc/calcdetails.html
public struct SolarCalculator: Sendable {
    public let latitude: Double
    public let longitude: Double
    public let timeZone: TimeZone

    public init(latitude: Double, longitude: Double, timeZone: TimeZone) {
        self.latitude = latitude
        self.longitude = longitude
        self.timeZone = timeZone
    }

    // MARK: - Public results

    public struct SolarTimes: Sendable {
        public let date: Date
        public let sunrise: Date?
        public let sunset: Date?
        public let solarNoon: Date?

        public var hasSunrise: Bool { sunrise != nil }
        public var hasSunset: Bool { sunset != nil }
    }

    /// Compute sunrise, sunset, and solar noon for a given civil date.
    public func times(for date: Date) -> SolarTimes {
        let cal = gregorian
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        guard let year = comps.year, let month = comps.month, let day = comps.day else {
            return SolarTimes(date: date, sunrise: nil, sunset: nil, solarNoon: nil)
        }
        let jd = julianDay(year: year, month: month, day: day)
        let tzOffset = Double(timeZone.secondsFromGMT(for: date)) / 3600.0
        let noon = solarNoonMinutes(jd: jd, longitude: longitude, tzOffset: tzOffset)
        let ha = hourAngle(jd: jd, latitude: latitude, angle: 0.8333)

        let solarNoonDate = minutesToDate(noon, year: year, month: month, day: day)

        if let ha {
            let riseMin = noon - ha * 4
            let setMin = noon + ha * 4
            return SolarTimes(
                date: date,
                sunrise: minutesToDate(riseMin, year: year, month: month, day: day),
                sunset: minutesToDate(setMin, year: year, month: month, day: day),
                solarNoon: solarNoonDate
            )
        }

        // Polar day or polar night — no sunrise/sunset
        return SolarTimes(date: date, sunrise: nil, sunset: nil, solarNoon: solarNoonDate)
    }

    /// Compute the time when the sun reaches a given angle below the horizon.
    /// Used for dawn (e.g., 16.1°) and nightfall (e.g., 8.5°).
    /// Returns nil at extreme latitudes where the angle is never reached.
    public func sunAngleTime(
        for date: Date, angle: Double, rising: Bool
    ) -> Date? {
        let cal = gregorian
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        guard let year = comps.year, let month = comps.month, let day = comps.day else {
            return nil
        }
        let jd = julianDay(year: year, month: month, day: day)
        let tzOffset = Double(timeZone.secondsFromGMT(for: date)) / 3600.0
        let noon = solarNoonMinutes(jd: jd, longitude: longitude, tzOffset: tzOffset)
        guard let ha = hourAngle(jd: jd, latitude: latitude, angle: angle) else {
            return nil
        }
        let minutes = rising ? (noon - ha * 4) : (noon + ha * 4)
        return minutesToDate(minutes, year: year, month: month, day: day)
    }

    // MARK: - NOAA Algorithm

    private var gregorian: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        return cal
    }

    /// Julian Day Number for a calendar date.
    func julianDay(year: Int, month: Int, day: Int) -> Double {
        var y = Double(year)
        var m = Double(month)
        if m <= 2 {
            y -= 1
            m += 12
        }
        let a = floor(y / 100)
        let b = 2 - a + floor(a / 4)
        return floor(365.25 * (y + 4716)) + floor(30.6001 * (m + 1)) + Double(day) + b - 1524.5
    }

    /// Julian Century from Julian Day.
    private func julianCentury(_ jd: Double) -> Double {
        (jd - 2451545.0) / 36525.0
    }

    /// Geometric mean longitude of the sun (degrees).
    private func sunMeanLongitude(_ t: Double) -> Double {
        var l = 280.46646 + t * (36000.76983 + 0.0003032 * t)
        l = l.truncatingRemainder(dividingBy: 360)
        if l < 0 { l += 360 }
        return l
    }

    /// Geometric mean anomaly of the sun (degrees).
    private func sunMeanAnomaly(_ t: Double) -> Double {
        357.52911 + t * (35999.05029 - 0.0001537 * t)
    }

    /// Eccentricity of Earth's orbit.
    private func earthOrbitEccentricity(_ t: Double) -> Double {
        0.016708634 - t * (0.000042037 + 0.0000001267 * t)
    }

    /// Sun equation of center (degrees).
    private func sunEquationOfCenter(_ t: Double) -> Double {
        let m = sunMeanAnomaly(t)
        let mr = m * .pi / 180
        let c = sin(mr) * (1.914602 - t * (0.004817 + 0.000014 * t))
            + sin(2 * mr) * (0.019993 - 0.000101 * t)
            + sin(3 * mr) * 0.000289
        return c
    }

    /// Sun true longitude (degrees).
    private func sunTrueLongitude(_ t: Double) -> Double {
        sunMeanLongitude(t) + sunEquationOfCenter(t)
    }

    /// Sun apparent longitude (degrees).
    private func sunApparentLongitude(_ t: Double) -> Double {
        let omega = 125.04 - 1934.136 * t
        return sunTrueLongitude(t) - 0.00569 - 0.00478 * sin(omega * .pi / 180)
    }

    /// Mean obliquity of the ecliptic (degrees).
    private func meanObliquity(_ t: Double) -> Double {
        23.0 + (26.0 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60.0) / 60.0
    }

    /// Corrected obliquity (degrees).
    private func correctedObliquity(_ t: Double) -> Double {
        let omega = 125.04 - 1934.136 * t
        return meanObliquity(t) + 0.00256 * cos(omega * .pi / 180)
    }

    /// Solar declination (degrees).
    private func solarDeclination(_ t: Double) -> Double {
        let e = correctedObliquity(t) * .pi / 180
        let lambda = sunApparentLongitude(t) * .pi / 180
        return asin(sin(e) * sin(lambda)) * 180 / .pi
    }

    /// Equation of time (minutes).
    private func equationOfTime(_ t: Double) -> Double {
        let e = correctedObliquity(t) * .pi / 180
        let l0 = sunMeanLongitude(t) * .pi / 180
        let ecc = earthOrbitEccentricity(t)
        let m = sunMeanAnomaly(t) * .pi / 180

        let y = tan(e / 2) * tan(e / 2)

        let eq = y * sin(2 * l0)
            - 2 * ecc * sin(m)
            + 4 * ecc * y * sin(m) * cos(2 * l0)
            - 0.5 * y * y * sin(4 * l0)
            - 1.25 * ecc * ecc * sin(2 * m)

        return 4 * eq * 180 / .pi
    }

    /// Hour angle for a given solar depression angle (degrees).
    /// Standard sunrise/sunset uses 0.8333° (accounting for refraction and solar radius).
    /// Returns nil if the sun never reaches this angle (polar conditions).
    func hourAngle(jd: Double, latitude: Double, angle: Double) -> Double? {
        let t = julianCentury(jd)
        let decl = solarDeclination(t)
        let latRad = latitude * .pi / 180
        let declRad = decl * .pi / 180
        let angleRad = angle * .pi / 180

        let cosHA = (cos((.pi / 2) + angleRad) - sin(latRad) * sin(declRad))
            / (cos(latRad) * cos(declRad))

        guard cosHA >= -1 && cosHA <= 1 else { return nil }
        return acos(cosHA) * 180 / .pi
    }

    /// Solar noon in minutes from midnight (local time).
    private func solarNoonMinutes(jd: Double, longitude: Double, tzOffset: Double) -> Double {
        let t = julianCentury(jd)
        let eqTime = equationOfTime(t)
        return 720 - 4 * longitude - eqTime + tzOffset * 60
    }

    /// Convert minutes-from-midnight to a Date.
    private func minutesToDate(
        _ minutes: Double, year: Int, month: Int, day: Int
    ) -> Date? {
        guard minutes.isFinite else { return nil }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        guard let midnight = cal.date(
            from: DateComponents(year: year, month: month, day: day, hour: 0, minute: 0, second: 0)
        ) else { return nil }
        return midnight.addingTimeInterval(minutes * 60)
    }
}
