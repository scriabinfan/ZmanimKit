import Foundation

/// Hebrew calendar date with proper month names and display formatting.
/// Uses Foundation's Hebrew calendar for date conversion.
public struct HebrewDate: Sendable, Equatable, Hashable {
    public let year: Int
    public let month: Int
    public let day: Int
    public let weekday: Int
    public let isLeapYear: Bool

    public init(from date: Date, timeZone: TimeZone = .current) {
        var cal = Calendar(identifier: .hebrew)
        cal.timeZone = timeZone
        year = cal.component(.year, from: date)
        month = cal.component(.month, from: date)
        day = cal.component(.day, from: date)
        weekday = cal.component(.weekday, from: date)
        isLeapYear = [0, 3, 6, 8, 11, 14, 17].contains(year % 19)
    }

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
        self.weekday = 0
        self.isLeapYear = [0, 3, 6, 8, 11, 14, 17].contains(year % 19)
    }

    // MARK: - Month names

    /// Foundation's Hebrew calendar month numbering:
    /// 1=Tishrei, 2=Cheshvan, 3=Kislev, 4=Tevet, 5=Shevat,
    /// 6=Adar I (or Adar in non-leap), 7=Adar II (leap only, otherwise Nisan),
    /// In a leap year months shift: 7=Nisan becomes 8=Nisan, etc.
    /// Foundation handles this; we just need to map the numbers to names.
    public var monthName: String {
        HebrewDate.monthName(month: month, isLeapYear: isLeapYear)
    }

    public var monthNameHebrew: String {
        HebrewDate.monthNameHebrew(month: month, isLeapYear: isLeapYear)
    }

    public static func monthName(month: Int, isLeapYear: Bool) -> String {
        switch month {
        case 1: return "Tishrei"
        case 2: return "Cheshvan"
        case 3: return "Kislev"
        case 4: return "Tevet"
        case 5: return "Shevat"
        case 6: return isLeapYear ? "Adar I" : "Adar"
        case 7:
            if isLeapYear { return "Adar II" }
            return "Nisan"
        case 8: return isLeapYear ? "Nisan" : "Iyyar"
        case 9: return isLeapYear ? "Iyyar" : "Sivan"
        case 10: return isLeapYear ? "Sivan" : "Tammuz"
        case 11: return isLeapYear ? "Tammuz" : "Av"
        case 12: return isLeapYear ? "Av" : "Elul"
        case 13: return "Elul"
        default: return "Unknown"
        }
    }

    public static func monthNameHebrew(month: Int, isLeapYear: Bool) -> String {
        switch month {
        case 1: return "תשרי"
        case 2: return "חשוון"
        case 3: return "כסלו"
        case 4: return "טבת"
        case 5: return "שבט"
        case 6: return isLeapYear ? "אדר א׳" : "אדר"
        case 7:
            if isLeapYear { return "אדר ב׳" }
            return "ניסן"
        case 8: return isLeapYear ? "ניסן" : "אייר"
        case 9: return isLeapYear ? "אייר" : "סיוון"
        case 10: return isLeapYear ? "סיוון" : "תמוז"
        case 11: return isLeapYear ? "תמוז" : "אב"
        case 12: return isLeapYear ? "אב" : "אלול"
        case 13: return "אלול"
        default: return ""
        }
    }

    // MARK: - Display

    /// e.g. "15 Tishrei 5787"
    public var formatted: String {
        "\(day) \(monthName) \(year)"
    }

    /// e.g. "ט״ו תשרי תשפ״ז"
    public var formattedHebrew: String {
        "\(hebrewDayString) \(monthNameHebrew) \(hebrewYearString)"
    }

    /// Hebrew numeral for the day (e.g., ט״ו for 15).
    public var hebrewDayString: String {
        HebrewNumerals.dayString(day)
    }

    /// Hebrew numeral for the year (e.g., תשפ״ז for 5787).
    public var hebrewYearString: String {
        HebrewNumerals.yearString(year)
    }

    // MARK: - Year properties

    /// Number of days in the current Hebrew month.
    public func daysInMonth(using timeZone: TimeZone = .gmt) -> Int {
        var cal = Calendar(identifier: .hebrew)
        cal.timeZone = timeZone
        guard let date = cal.date(from: DateComponents(year: year, month: month, day: 1)),
              let range = cal.range(of: .day, in: .month, for: date) else { return 30 }
        return range.count
    }

    /// Number of days in Kislev (29 or 30 — determines year type).
    public var daysInKislev: Int {
        var cal = Calendar(identifier: .hebrew)
        cal.timeZone = .gmt
        guard let kislev = cal.date(from: DateComponents(year: year, month: 3, day: 1)),
              let range = cal.range(of: .day, in: .month, for: kislev) else { return 30 }
        return range.count
    }

    // MARK: - Conversion

    /// Convert a Hebrew date back to a Gregorian Date.
    public func toGregorianDate(timeZone: TimeZone = .gmt) -> Date? {
        var cal = Calendar(identifier: .hebrew)
        cal.timeZone = timeZone
        return cal.date(from: DateComponents(year: year, month: month, day: day))
    }

    /// Whether this is Shabbat (Saturday = weekday 7).
    public var isShabbat: Bool { weekday == 7 }

    /// Whether this is Rosh Chodesh.
    public var isRoshChodesh: Bool { (day == 1 && month != 1) || day == 30 }
}

// MARK: - Sunset-aware date boundary

public extension HebrewDate {
    /// Returns the religious Hebrew date, advancing by one day if past sunset.
    /// Jewish days begin at sunset.
    static func religiousDate(
        at civilDate: Date, sunset: Date?, timeZone: TimeZone
    ) -> HebrewDate {
        guard let sunset, civilDate >= sunset else {
            return HebrewDate(from: civilDate, timeZone: timeZone)
        }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        guard cal.isDate(civilDate, inSameDayAs: sunset) else {
            return HebrewDate(from: civilDate, timeZone: timeZone)
        }
        let tomorrow = cal.date(byAdding: .day, value: 1, to: civilDate) ?? civilDate
        return HebrewDate(from: tomorrow, timeZone: timeZone)
    }
}

// MARK: - Hebrew numerals

public enum HebrewNumerals {
    private static let ones = ["", "א", "ב", "ג", "ד", "ה", "ו", "ז", "ח", "ט"]
    private static let tens = ["", "י", "כ", "ל", "מ", "נ", "ס", "ע", "פ", "צ"]
    private static let hundreds = ["", "ק", "ר", "ש", "ת"]

    public static func dayString(_ day: Int) -> String {
        guard day > 0 && day <= 30 else { return "\(day)" }
        // Special cases: 15 = ט״ו, 16 = ט״ז (avoid divine name letters)
        if day == 15 { return "ט״ו" }
        if day == 16 { return "ט״ז" }
        let t = day / 10
        let o = day % 10
        let letters = tens[t] + ones[o]
        return insertGershayim(letters)
    }

    public static func yearString(_ year: Int) -> String {
        let y = year % 1000
        var result = ""
        var remaining = y

        // Hundreds
        while remaining >= 400 {
            result += hundreds[4]
            remaining -= 400
        }
        if remaining >= 100 {
            result += hundreds[remaining / 100]
            remaining %= 100
        }

        // Tens and ones — same 15/16 exception
        if remaining == 15 {
            result += "טו"
        } else if remaining == 16 {
            result += "טז"
        } else {
            if remaining >= 10 {
                result += tens[remaining / 10]
                remaining %= 10
            }
            if remaining > 0 {
                result += ones[remaining]
            }
        }

        return insertGershayim(result)
    }

    private static func insertGershayim(_ s: String) -> String {
        guard s.count > 1 else {
            return s + "׳"
        }
        let idx = s.index(s.endIndex, offsetBy: -1)
        return String(s[..<idx]) + "״" + String(s[idx...])
    }
}
