import Foundation

/// Jewish calendar day with holiday detection, occasion tracking,
/// Israel/Diaspora divergence, fast postponement, and prayer context.
public struct JewishDay: Sendable, Equatable {
    public let hebrewDate: HebrewDate
    public let israel: Bool

    public init(hebrewDate: HebrewDate, israel: Bool) {
        self.hebrewDate = hebrewDate
        self.israel = israel
    }

    public init(from date: Date, timeZone: TimeZone, israel: Bool) {
        self.hebrewDate = HebrewDate(from: date, timeZone: timeZone)
        self.israel = israel
    }

    /// Convenience accessors.
    public var year: Int { hebrewDate.year }
    public var month: Int { hebrewDate.month }
    public var day: Int { hebrewDate.day }
    public var weekday: Int { hebrewDate.weekday }
    public var isLeapYear: Bool { hebrewDate.isLeapYear }
    public var daysInKislev: Int { hebrewDate.daysInKislev }

    // MARK: - Shabbat and Rosh Chodesh

    public var isShabbat: Bool { weekday == 7 }
    public var isRoshChodesh: Bool { (day == 1 && month != 1) || day == 30 }

    // MARK: - Ten Days of Repentance

    public var isTenDays: Bool { month == 1 && day <= 10 }

    // MARK: - Chanukah (25 Kislev for 8 days)

    public var isChanukah: Bool {
        (month == 3 && day >= 25) || (month == 4 && day <= 33 - daysInKislev)
    }

    // MARK: - Yom Tov

    public var isYomTov: Bool {
        // Tishrei: RH 1-2, YK 10, Sukkot 15 (+16 galut), SA 22 (+23 galut)
        if month == 1 {
            if [1, 2, 10, 15, 22].contains(day) { return true }
            if !israel && [16, 23].contains(day) { return true }
        }
        if isPesach || isShavuot || isSukkot || isSheminiAtzeret {
            return true
        }
        return isRoshHashanah || isYomKippur
    }

    // MARK: - Chol HaMoed

    /// Nisan month number depends on leap year.
    private var nisanMonth: Int { isLeapYear ? 8 : 7 }
    private var sivanMonth: Int { isLeapYear ? 10 : 9 }
    private var tammuzMonth: Int { isLeapYear ? 11 : 10 }
    private var avMonth: Int { isLeapYear ? 12 : 11 }
    private var elulMonth: Int { isLeapYear ? 13 : 12 }
    private var adarMonth: Int { isLeapYear ? 7 : 6 }

    public var isCholHaMoed: Bool {
        // Pesach Chol HaMoed
        if month == nisanMonth && (israel ? 16...20 : 17...20).contains(day) { return true }
        // Sukkot Chol HaMoed
        if month == 1 && (israel ? 16...21 : 17...21).contains(day) { return true }
        return false
    }

    public var isCholHamoedPesach: Bool {
        month == nisanMonth && (israel ? 16...20 : 17...20).contains(day)
    }

    public var isCholHamoedSukkot: Bool {
        month == 1 && (israel ? 16...21 : 17...21).contains(day)
    }

    // MARK: - Specific festivals

    public var isPesach: Bool {
        month == nisanMonth && (israel ? [15, 21] : [15, 16, 21, 22]).contains(day)
    }

    public var isShavuot: Bool {
        month == sivanMonth && (israel ? day == 6 : [6, 7].contains(day))
    }

    public var isSukkot: Bool {
        month == 1 && (israel ? day == 15 : [15, 16].contains(day))
    }

    public var isSheminiAtzeret: Bool {
        month == 1 && (israel ? day == 22 : [22, 23].contains(day))
    }

    public var isRoshHashanah: Bool { month == 1 && day <= 2 }
    public var isYomKippur: Bool { month == 1 && day == 10 }

    // MARK: - Purim

    /// Standard Purim on 14 Adar (or Adar II in leap year).
    /// Shushan Purim (walled cities) on 15 — set walledCity separately.
    public var isPurim: Bool {
        month == adarMonth && day == 14
    }

    public var isShushanPurim: Bool {
        month == adarMonth && day == 15
    }

    // MARK: - Minor fasts

    public var minorFast: MinorFast? {
        // Tzom Gedaliah: 3 Tishrei, postponed to Sunday if Shabbat
        if month == 1 && ((day == 3 && !isShabbat) || (day == 4 && weekday == 1)) {
            return .tzomGedaliah
        }
        // 10 Tevet: never postponed (falls on Friday at most)
        if month == 4 && day == 10 {
            return .asaraBeTevet
        }
        // 17 Tammuz: postponed to Sunday if Shabbat
        if month == tammuzMonth
            && ((day == 17 && !isShabbat) || (day == 18 && weekday == 1)) {
            return .shivaAsarBeTammuz
        }
        // Ta'anit Esther: 13 Adar, advanced to Thursday if Shabbat
        if month == adarMonth
            && ((day == 13 && !isShabbat) || (day == 11 && weekday == 5)) {
            return .taanitEsther
        }
        return nil
    }

    // MARK: - Tisha B'Av

    public var isTishaBav: Bool {
        month == avMonth && ((day == 9 && !isShabbat) || (day == 10 && weekday == 1))
    }

    // MARK: - Hallel

    public var hallelType: HallelType? {
        // Full Hallel
        if isChanukah { return .full }
        if month == nisanMonth && (15...(israel ? 21 : 22)).contains(day) { return .full }
        if isShavuot { return .full }
        if isSukkot || (month == 1 && day == 15) || (!israel && month == 1 && day == 16) {
            return .full
        }
        if isSheminiAtzeret { return .full }

        // Partial Hallel
        if isRoshChodesh { return .partial }
        if isCholHamoedPesach { return .partial }

        return nil
    }

    // MARK: - Musaf

    public var needsMusaf: Bool {
        isRoshChodesh || isCholHaMoed || isYomTov || isShabbat || isSheminiAtzeret
    }

    // MARK: - Rain

    /// Rain mention (Mashiv HaRuach): from Shemini Atzeret Musaf through Pesach Musaf.
    public var hasRainMention: Bool {
        // Tishrei 22+ through Nisan 14
        if month == 1 && day >= 22 { return true }
        if (2...3).contains(month) { return true }
        if month == 4 { return true }
        if month == 5 { return true }
        if isLeapYear {
            if (6...7).contains(month) { return true }
            if month == 8 && day < 15 { return true }
        } else {
            if month == 6 { return true }
            if month == 7 && day < 15 { return true }
        }
        return false
    }

    /// Rain request (Vesein Tal Umatar):
    /// Israel: from 7 Cheshvan. Diaspora: from ~Dec 4/5 (60 days after tekufah).
    /// Through Mincha of Erev Pesach.
    public var hasRainRequest: Bool {
        if israel {
            // 7 Cheshvan through 14 Nisan
            if month == 2 && day >= 7 { return true }
            if (3...5).contains(month) { return true }
            if isLeapYear {
                if (6...7).contains(month) { return true }
                if month == 8 && day <= 14 { return true }
            } else {
                if month == 6 { return true }
                if month == 7 && day <= 14 { return true }
            }
            return false
        } else {
            // Diaspora: approximate — starts ~Dec 4/5 (60 days after fall equinox)
            // This needs the Gregorian date; we encode the Cheshvan threshold
            // conservatively. Full tekufah calculation is a known follow-up.
            if month == 2 { return false }
            if month == 3 { return true }
            if month == 4 { return true }
            if month == 5 { return true }
            if isLeapYear {
                if (6...7).contains(month) { return true }
                if month == 8 && day <= 14 { return true }
            } else {
                if month == 6 { return true }
                if month == 7 && day <= 14 { return true }
            }
            return false
        }
    }

    // MARK: - Occasion set

    /// Returns the set of active occasions for this day.
    public var occasions: Set<JewishOccasion> {
        var result = Set<JewishOccasion>()
        if isShabbat { result.insert(.shabbat) }
        if isRoshChodesh { result.insert(.roshChodesh) }
        if isChanukah { result.insert(.chanukah) }
        if isPurim { result.insert(.purim) }
        if isPesach { result.insert(.pesach) }
        if isCholHamoedPesach { result.insert(.cholHamoedPesach) }
        if isShavuot { result.insert(.shavuot) }
        if isSukkot { result.insert(.sukkot) }
        if isCholHamoedSukkot { result.insert(.cholHamoedSukkot) }
        if isSheminiAtzeret { result.insert(.sheminiAtzeret) }
        if isRoshHashanah { result.insert(.roshHashanah) }
        if isYomKippur { result.insert(.yomKippur) }
        if isTenDays { result.insert(.tenDays) }
        if minorFast != nil { result.insert(.minorFast) }
        if isTishaBav { result.insert(.tishaBav) }
        return result
    }

    // MARK: - Summary labels

    public var summary: [String] {
        var result: [String] = []
        if isShabbat { result.append("Shabbat") }
        if isRoshHashanah { result.append("Rosh Hashanah") }
        if isYomKippur { result.append("Yom Kippur") }
        if isSukkot { result.append("Sukkot") }
        if isSheminiAtzeret { result.append("Shemini Atzeret") }
        if isPesach { result.append("Pesach") }
        if isShavuot { result.append("Shavuot") }
        if isCholHamoedPesach { result.append("Chol HaMoed Pesach") }
        if isCholHamoedSukkot { result.append("Chol HaMoed Sukkot") }
        if isRoshChodesh { result.append("Rosh Chodesh") }
        if isChanukah { result.append("Chanukah") }
        if isPurim { result.append("Purim") }
        if let fast = minorFast { result.append(fast.displayName) }
        if isTishaBav { result.append("Tisha B'Av") }
        if isTenDays && !isRoshHashanah && !isYomKippur {
            result.append("Ten Days of Repentance")
        }
        if let hallel = hallelType {
            result.append("\(hallel == .full ? "Full" : "Partial") Hallel")
        }
        return result
    }
}

// MARK: - Occasion enum

public enum JewishOccasion: String, Sendable, Hashable, CaseIterable {
    case shabbat, roshChodesh, chanukah, purim
    case pesach, shavuot, sukkot, sheminiAtzeret
    case cholHamoedPesach, cholHamoedSukkot
    case roshHashanah, yomKippur
    case tenDays
    case minorFast
    case tishaBav

    public var displayName: String {
        switch self {
        case .shabbat: "Shabbat"
        case .roshChodesh: "Rosh Chodesh"
        case .chanukah: "Chanukah"
        case .purim: "Purim"
        case .pesach: "Pesach"
        case .shavuot: "Shavuot"
        case .sukkot: "Sukkot"
        case .sheminiAtzeret: "Shemini Atzeret"
        case .cholHamoedPesach: "Chol HaMoed Pesach"
        case .cholHamoedSukkot: "Chol HaMoed Sukkot"
        case .roshHashanah: "Rosh Hashanah"
        case .yomKippur: "Yom Kippur"
        case .tenDays: "Ten Days of Repentance"
        case .minorFast: "Fast Day"
        case .tishaBav: "Tisha B'Av"
        }
    }
}

// MARK: - Minor fasts

public enum MinorFast: String, Sendable {
    case tzomGedaliah
    case asaraBeTevet
    case shivaAsarBeTammuz
    case taanitEsther

    public var displayName: String {
        switch self {
        case .tzomGedaliah: "Tzom Gedaliah"
        case .asaraBeTevet: "Asara B'Tevet"
        case .shivaAsarBeTammuz: "Shiva Asar B'Tammuz"
        case .taanitEsther: "Ta'anit Esther"
        }
    }
}

// MARK: - Hallel type

public enum HallelType: String, Sendable {
    case full
    case partial
}

// MARK: - Annual holiday list

public struct AnnualHoliday: Sendable, Identifiable {
    public var id: String { "\(hebrewDate.year)-\(hebrewDate.month)-\(hebrewDate.day)-\(name)" }
    public let name: String
    public let hebrewDate: HebrewDate
    public let category: HolidayCategory
    public let isYomTov: Bool

    public var gregorianDate: Date? { hebrewDate.toGregorianDate() }
}

public enum HolidayCategory: String, Sendable {
    case major
    case minor
    case fast
    case roshChodesh
}

public enum JewishHolidays {
    /// Generate the list of holidays for a Hebrew year.
    public static func holidays(
        year: Int, israel: Bool
    ) -> [AnnualHoliday] {
        let leap = [0, 3, 6, 8, 11, 14, 17].contains(year % 19)
        let nisanMonth = leap ? 8 : 7
        let sivanMonth = leap ? 10 : 9
        let adarMonth = leap ? 7 : 6

        var list: [AnnualHoliday] = []

        func add(_ name: String, _ month: Int, _ day: Int, _ cat: HolidayCategory, yt: Bool = false) {
            list.append(AnnualHoliday(
                name: name,
                hebrewDate: HebrewDate(year: year, month: month, day: day),
                category: cat, isYomTov: yt
            ))
        }

        // Tishrei
        add("Rosh Hashanah I", 1, 1, .major, yt: true)
        add("Rosh Hashanah II", 1, 2, .major, yt: true)
        add("Tzom Gedaliah", 1, 3, .fast)
        add("Yom Kippur", 1, 10, .major, yt: true)
        add("Sukkot I", 1, 15, .major, yt: true)
        if !israel { add("Sukkot II", 1, 16, .major, yt: true) }
        for d in (israel ? 16 : 17)...20 {
            add("Chol HaMoed Sukkot \(d - (israel ? 15 : 16))", 1, d, .minor)
        }
        add("Hoshana Rabbah", 1, 21, .minor)
        add("Shemini Atzeret", 1, 22, .major, yt: true)
        if !israel { add("Simchat Torah", 1, 23, .major, yt: true) }

        // Kislev-Tevet: Chanukah
        for d in 25...30 { add("Chanukah \(d - 24)", 3, d, .minor) }
        let remaining = 8 - (30 - 25 + 1)
        for d in 1...remaining { add("Chanukah \(d + 30 - 25 + 1 - 1)", 4, d, .minor) }

        // Tevet
        add("Asara B'Tevet", 4, 10, .fast)

        // Adar
        add("Ta'anit Esther", adarMonth, 13, .fast)
        add("Purim", adarMonth, 14, .minor)
        add("Shushan Purim", adarMonth, 15, .minor)

        // Nisan
        add("Pesach I", nisanMonth, 15, .major, yt: true)
        if !israel { add("Pesach II", nisanMonth, 16, .major, yt: true) }
        for d in (israel ? 16 : 17)...20 {
            add("Chol HaMoed Pesach \(d - (israel ? 15 : 16))", nisanMonth, d, .minor)
        }
        add("Pesach VII", nisanMonth, 21, .major, yt: true)
        if !israel { add("Pesach VIII", nisanMonth, 22, .major, yt: true) }

        // Sivan
        add("Shavuot", sivanMonth, 6, .major, yt: true)
        if !israel { add("Shavuot II", sivanMonth, 7, .major, yt: true) }

        // Summer fasts
        let tammuzMonth = leap ? 11 : 10
        add("Shiva Asar B'Tammuz", tammuzMonth, 17, .fast)
        let avMonth = leap ? 12 : 11
        add("Tisha B'Av", avMonth, 9, .fast)

        return list
    }
}
