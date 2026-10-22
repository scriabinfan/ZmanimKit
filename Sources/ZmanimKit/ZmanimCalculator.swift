import Foundation

/// Halachic daily times derived from solar positions.
public struct ZmanimCalculator: Sendable {
    public let solar: SolarCalculator
    public let elevation: Double

    public init(
        latitude: Double, longitude: Double,
        timeZone: TimeZone, elevation: Double = 0
    ) {
        self.solar = SolarCalculator(
            latitude: latitude, longitude: longitude, timeZone: timeZone
        )
        self.elevation = elevation
    }

    // MARK: - Daily times

    /// Compute all zmanim for a given date using the specified method.
    public func zmanim(for date: Date, method: ZmanimMethod = .gra) -> DailyZmanim {
        let times = solar.times(for: date)
        return DailyZmanim(
            date: date,
            sunrise: times.sunrise,
            sunset: times.sunset,
            solarNoon: times.solarNoon,
            alotHaShachar: dawn(for: date, method: method),
            misheyakir: misheyakir(for: date, method: method),
            latestShema: latestShema(for: date, method: method),
            latestShacharit: latestShacharit(for: date, method: method),
            chatzot: times.solarNoon,
            minchaGedola: minchaGedola(for: date, method: method),
            minchaKetana: minchaKetana(for: date, method: method),
            plagHaMincha: plagHaMincha(for: date, method: method),
            nightfall: nightfall(for: date, method: method),
            nightfallStringent: nightfallStringent(for: date, method: method),
            chatzotNight: chatzotNight(for: date),
            method: method
        )
    }

    // MARK: - Individual zmanim

    /// Dawn (Alot HaShachar).
    public func dawn(for date: Date, method: ZmanimMethod = .gra) -> Date? {
        solar.sunAngleTime(for: date, angle: method.dawnAngle, rising: true)
    }

    /// Earliest tallit and tefillin (Misheyakir).
    public func misheyakir(for date: Date, method: ZmanimMethod = .gra) -> Date? {
        solar.sunAngleTime(for: date, angle: method.misheyakirAngle, rising: true)
    }

    /// Latest Shema — 3 proportional hours into the day.
    public func latestShema(for date: Date, method: ZmanimMethod = .gra) -> Date? {
        guard let (start, hourLength) = proportionalHour(for: date, method: method) else {
            return nil
        }
        return start.addingTimeInterval(3 * hourLength)
    }

    /// Latest Shacharit Amidah — 4 proportional hours.
    public func latestShacharit(for date: Date, method: ZmanimMethod = .gra) -> Date? {
        guard let (start, hourLength) = proportionalHour(for: date, method: method) else {
            return nil
        }
        return start.addingTimeInterval(4 * hourLength)
    }

    /// Mincha Gedola — 6.5 proportional hours (earliest Mincha).
    public func minchaGedola(for date: Date, method: ZmanimMethod = .gra) -> Date? {
        guard let (start, hourLength) = proportionalHour(for: date, method: method) else {
            return nil
        }
        return start.addingTimeInterval(6.5 * hourLength)
    }

    /// Mincha Ketana — 9.5 proportional hours (preferred Mincha).
    public func minchaKetana(for date: Date, method: ZmanimMethod = .gra) -> Date? {
        guard let (start, hourLength) = proportionalHour(for: date, method: method) else {
            return nil
        }
        return start.addingTimeInterval(9.5 * hourLength)
    }

    /// Plag HaMincha — 10.75 proportional hours.
    public func plagHaMincha(for date: Date, method: ZmanimMethod = .gra) -> Date? {
        guard let (start, hourLength) = proportionalHour(for: date, method: method) else {
            return nil
        }
        return start.addingTimeInterval(10.75 * hourLength)
    }

    /// Ordinary nightfall (tzeit hakochavim).
    public func nightfall(for date: Date, method: ZmanimMethod = .gra) -> Date? {
        solar.sunAngleTime(for: date, angle: method.nightfallAngle, rising: false)
    }

    /// Stringent nightfall for Shabbat/Yom Tov ending.
    public func nightfallStringent(for date: Date, method: ZmanimMethod = .gra) -> Date? {
        solar.sunAngleTime(for: date, angle: method.shabbatEndAngle, rising: false)
    }

    /// Midnight (Chatzot Layla) — midpoint of nighttime.
    public func chatzotNight(for date: Date) -> Date? {
        let times = solar.times(for: date)
        guard let sunset = times.sunset else { return nil }
        let cal = Calendar(identifier: .gregorian)
        let tomorrow = cal.date(byAdding: .day, value: 1, to: date)!
        let tomorrowTimes = solar.times(for: tomorrow)
        guard let nextSunrise = tomorrowTimes.sunrise else { return nil }
        let midpoint = sunset.timeIntervalSince1970
            + (nextSunrise.timeIntervalSince1970 - sunset.timeIntervalSince1970) / 2
        return Date(timeIntervalSince1970: midpoint)
    }

    /// Candle lighting time — sunset minus the specified offset.
    public func candleLighting(for date: Date, minutesBefore: Int = 18) -> Date? {
        let times = solar.times(for: date)
        return times.sunset?.addingTimeInterval(-Double(minutesBefore) * 60)
    }

    /// Fixed-minute nightfall (e.g., 42, 50, or 72 minutes after sunset).
    public func fixedMinuteNightfall(for date: Date, minutes: Int) -> Date? {
        let times = solar.times(for: date)
        return times.sunset?.addingTimeInterval(Double(minutes) * 60)
    }

    // MARK: - Proportional hours

    /// Returns (dayStart, hourLength) for the given method.
    /// GRA: sunrise to sunset. MGA: dawn to nightfall (varies by method).
    func proportionalHour(
        for date: Date, method: ZmanimMethod
    ) -> (start: Date, hourLength: TimeInterval)? {
        let times = solar.times(for: date)

        switch method {
        case .gra:
            guard let rise = times.sunrise, let set = times.sunset else { return nil }
            let dayLength = set.timeIntervalSince(rise)
            return (rise, dayLength / 12)

        case .mga72:
            guard let rise = times.sunrise, let set = times.sunset else { return nil }
            let start = rise.addingTimeInterval(-72 * 60)
            let end = set.addingTimeInterval(72 * 60)
            let dayLength = end.timeIntervalSince(start)
            return (start, dayLength / 12)

        case .mga16Point1:
            guard let dawnTime = dawn(for: date, method: method),
                  let nightTime = nightfall(for: date, method: method) else { return nil }
            let dayLength = nightTime.timeIntervalSince(dawnTime)
            return (dawnTime, dayLength / 12)

        case .baalHaTanya:
            guard let dawnTime = solar.sunAngleTime(for: date, angle: 16.9, rising: true),
                  let nightTime = solar.sunAngleTime(for: date, angle: 8.5, rising: false)
            else { return nil }
            let dayLength = nightTime.timeIntervalSince(dawnTime)
            return (dawnTime, dayLength / 12)
        }
    }
}

// MARK: - Daily zmanim result

public struct DailyZmanim: Sendable {
    public let date: Date
    public let sunrise: Date?
    public let sunset: Date?
    public let solarNoon: Date?
    public let alotHaShachar: Date?
    public let misheyakir: Date?
    public let latestShema: Date?
    public let latestShacharit: Date?
    public let chatzot: Date?
    public let minchaGedola: Date?
    public let minchaKetana: Date?
    public let plagHaMincha: Date?
    public let nightfall: Date?
    public let nightfallStringent: Date?
    public let chatzotNight: Date?
    public let method: ZmanimMethod

    /// All available times sorted chronologically, with labels.
    public var entries: [(label: String, hebrew: String, time: Date)] {
        var result: [(String, String, Date)] = []
        func add(_ label: String, _ hebrew: String, _ time: Date?) {
            if let time { result.append((label, hebrew, time)) }
        }
        add("Alot HaShachar", "עלות השחר", alotHaShachar)
        add("Misheyakir", "משיכיר", misheyakir)
        add("Sunrise", "הנץ החמה", sunrise)
        add("Latest Shema", "סוף זמן שמע", latestShema)
        add("Latest Shacharit", "סוף זמן תפילה", latestShacharit)
        add("Chatzot", "חצות", chatzot)
        add("Mincha Gedola", "מנחה גדולה", minchaGedola)
        add("Mincha Ketana", "מנחה קטנה", minchaKetana)
        add("Plag HaMincha", "פלג המנחה", plagHaMincha)
        add("Sunset", "שקיעה", sunset)
        add("Nightfall", "צאת הכוכבים", nightfall)
        add("Nightfall (stringent)", "צאת הכוכבים (מחמיר)", nightfallStringent)
        add("Chatzot Layla", "חצות הלילה", chatzotNight)
        return result.sorted { $0.2 < $1.2 }
    }

    /// Number of available times (non-nil).
    public var availableCount: Int { entries.count }

    /// Names of unavailable times (polar or extreme latitude).
    public var unavailable: [String] {
        var result: [String] = []
        if alotHaShachar == nil { result.append("Alot HaShachar") }
        if sunrise == nil { result.append("Sunrise") }
        if sunset == nil { result.append("Sunset") }
        if nightfall == nil { result.append("Nightfall") }
        return result
    }
}

// MARK: - Timing method

public enum ZmanimMethod: String, Sendable, CaseIterable, Codable {
    case gra
    case mga72
    case mga16Point1
    case baalHaTanya

    public var displayName: String {
        switch self {
        case .gra: "GRA (Vilna Gaon)"
        case .mga72: "MGA (fixed 72 min)"
        case .mga16Point1: "MGA (16.1°)"
        case .baalHaTanya: "Baal HaTanya"
        }
    }

    var dawnAngle: Double {
        switch self {
        case .gra, .mga72: 16.1
        case .mga16Point1: 16.1
        case .baalHaTanya: 16.9
        }
    }

    var misheyakirAngle: Double {
        switch self {
        case .gra, .mga72, .mga16Point1: 11.5
        case .baalHaTanya: 10.2
        }
    }

    var nightfallAngle: Double {
        switch self {
        case .gra, .mga72, .mga16Point1: 7.083
        case .baalHaTanya: 6.0
        }
    }

    var shabbatEndAngle: Double {
        switch self {
        case .gra, .mga72, .mga16Point1: 8.5
        case .baalHaTanya: 8.5
        }
    }
}
