import Foundation

// MARK: - Parasha definition

/// A weekly Torah portion, or a double portion.
public struct Parasha: Sendable, Equatable, Hashable, Identifiable {
    public var id: String { name }
    public let index: Int
    public let name: String
    public let hebrew: String
    public let book: TorahBook
    public let doubleIndex: Int?
    public let doubleName: String?
    public let doubleHebrew: String?

    public var isDouble: Bool { doubleIndex != nil }

    public var displayName: String {
        if let dn = doubleName { return "\(name)-\(dn)" }
        return name
    }

    public var displayHebrew: String {
        if let dh = doubleHebrew { return "\(hebrew)־\(dh)" }
        return hebrew
    }
}

public enum TorahBook: String, Sendable, CaseIterable {
    case bereishit = "Bereishit"
    case shemot = "Shemot"
    case vayikra = "Vayikra"
    case bamidbar = "Bamidbar"
    case devarim = "Devarim"

    public var hebrew: String {
        switch self {
        case .bereishit: "בראשית"
        case .shemot: "שמות"
        case .vayikra: "ויקרא"
        case .bamidbar: "במדבר"
        case .devarim: "דברים"
        }
    }
}

// MARK: - Special Shabbatot

/// Special Shabbatot that have additional maftir/haftarah readings.
public enum SpecialShabbat: String, Sendable, CaseIterable {
    case shekalim
    case zachor
    case parah
    case haChodesh
    case haGadol
    case shuvah
    case chazon
    case nachamu

    public var displayName: String {
        switch self {
        case .shekalim: "Shabbat Shekalim"
        case .zachor: "Shabbat Zachor"
        case .parah: "Shabbat Parah"
        case .haChodesh: "Shabbat HaChodesh"
        case .haGadol: "Shabbat HaGadol"
        case .shuvah: "Shabbat Shuvah"
        case .chazon: "Shabbat Chazon"
        case .nachamu: "Shabbat Nachamu"
        }
    }

    public var hebrew: String {
        switch self {
        case .shekalim: "שבת שקלים"
        case .zachor: "שבת זכור"
        case .parah: "שבת פרה"
        case .haChodesh: "שבת החודש"
        case .haGadol: "שבת הגדול"
        case .shuvah: "שבת שובה"
        case .chazon: "שבת חזון"
        case .nachamu: "שבת נחמו"
        }
    }
}

// MARK: - Holiday Torah reading

/// Identifies the Torah reading for holidays/special days that override the weekly parasha.
public struct HolidayReading: Sendable, Equatable {
    public let name: String
    public let hebrew: String
    public let occasion: JewishOccasion?

    public static let roshHashanah1 = HolidayReading(
        name: "Rosh Hashanah Day 1", hebrew: "ראש השנה יום א׳", occasion: .roshHashanah)
    public static let roshHashanah2 = HolidayReading(
        name: "Rosh Hashanah Day 2", hebrew: "ראש השנה יום ב׳", occasion: .roshHashanah)
    public static let yomKippur = HolidayReading(
        name: "Yom Kippur", hebrew: "יום כיפור", occasion: .yomKippur)
    public static let sukkot1 = HolidayReading(
        name: "Sukkot Day 1", hebrew: "סוכות יום א׳", occasion: .sukkot)
    public static let sukkot2 = HolidayReading(
        name: "Sukkot Day 2", hebrew: "סוכות יום ב׳", occasion: .sukkot)
    public static let cholHamoedSukkot = HolidayReading(
        name: "Chol HaMoed Sukkot", hebrew: "חול המועד סוכות", occasion: .cholHamoedSukkot)
    public static let sheminiAtzeret = HolidayReading(
        name: "Shemini Atzeret", hebrew: "שמיני עצרת", occasion: .sheminiAtzeret)
    public static let pesach1 = HolidayReading(
        name: "Pesach Day 1", hebrew: "פסח יום א׳", occasion: .pesach)
    public static let pesach2 = HolidayReading(
        name: "Pesach Day 2", hebrew: "פסח יום ב׳", occasion: .pesach)
    public static let cholHamoedPesach = HolidayReading(
        name: "Chol HaMoed Pesach", hebrew: "חול המועד פסח", occasion: .cholHamoedPesach)
    public static let pesach7 = HolidayReading(
        name: "Pesach Day 7", hebrew: "פסח יום ז׳", occasion: .pesach)
    public static let pesach8 = HolidayReading(
        name: "Pesach Day 8", hebrew: "פסח יום ח׳", occasion: .pesach)
    public static let shavuot1 = HolidayReading(
        name: "Shavuot Day 1", hebrew: "שבועות יום א׳", occasion: .shavuot)
    public static let shavuot2 = HolidayReading(
        name: "Shavuot Day 2", hebrew: "שבועות יום ב׳", occasion: .shavuot)
}

// MARK: - Weekly reading result

/// The Torah reading for a given Shabbat.
public struct WeeklyReading: Sendable, Equatable {
    public let date: Date
    public let hebrewDate: HebrewDate
    /// The weekly parasha (nil when a holiday overrides).
    public let parasha: Parasha?
    /// Holiday reading that overrides the parasha (nil on regular Shabbatot).
    public let holidayReading: HolidayReading?
    /// Special Shabbat designation (additional maftir/haftarah).
    public let specialShabbat: SpecialShabbat?

    public var displayName: String {
        var parts: [String] = []
        if let p = parasha { parts.append(p.displayName) }
        if let h = holidayReading { parts.append(h.name) }
        if let s = specialShabbat { parts.append(s.displayName) }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Parasha catalog

public enum ParashaList {
    /// All 54 parashot in cycle order.
    public static let all: [(name: String, hebrew: String, book: TorahBook)] = [
        ("Bereishit", "בראשית", .bereishit),
        ("Noach", "נח", .bereishit),
        ("Lech Lecha", "לך לך", .bereishit),
        ("Vayera", "וירא", .bereishit),
        ("Chayei Sarah", "חיי שרה", .bereishit),
        ("Toldot", "תולדות", .bereishit),
        ("Vayetzei", "ויצא", .bereishit),
        ("Vayishlach", "וישלח", .bereishit),
        ("Vayeshev", "וישב", .bereishit),
        ("Miketz", "מקץ", .bereishit),
        ("Vayigash", "ויגש", .bereishit),
        ("Vayechi", "ויחי", .bereishit),
        ("Shemot", "שמות", .shemot),
        ("Vaera", "וארא", .shemot),
        ("Bo", "בא", .shemot),
        ("Beshalach", "בשלח", .shemot),
        ("Yitro", "יתרו", .shemot),
        ("Mishpatim", "משפטים", .shemot),
        ("Terumah", "תרומה", .shemot),
        ("Tetzaveh", "תצוה", .shemot),
        ("Ki Tisa", "כי תשא", .shemot),
        ("Vayakhel", "ויקהל", .shemot),
        ("Pekudei", "פקודי", .shemot),
        ("Vayikra", "ויקרא", .vayikra),
        ("Tzav", "צו", .vayikra),
        ("Shemini", "שמיני", .vayikra),
        ("Tazria", "תזריע", .vayikra),
        ("Metzora", "מצורע", .vayikra),
        ("Acharei Mot", "אחרי מות", .vayikra),
        ("Kedoshim", "קדושים", .vayikra),
        ("Emor", "אמור", .vayikra),
        ("Behar", "בהר", .vayikra),
        ("Bechukotai", "בחוקותי", .vayikra),
        ("Bamidbar", "במדבר", .bamidbar),
        ("Naso", "נשא", .bamidbar),
        ("Behaalotcha", "בהעלותך", .bamidbar),
        ("Shelach", "שלח", .bamidbar),
        ("Korach", "קרח", .bamidbar),
        ("Chukat", "חקת", .bamidbar),
        ("Balak", "בלק", .bamidbar),
        ("Pinchas", "פינחס", .bamidbar),
        ("Matot", "מטות", .bamidbar),
        ("Masei", "מסעי", .bamidbar),
        ("Devarim", "דברים", .devarim),
        ("Vaetchanan", "ואתחנן", .devarim),
        ("Eikev", "עקב", .devarim),
        ("Re'eh", "ראה", .devarim),
        ("Shoftim", "שופטים", .devarim),
        ("Ki Teitzei", "כי תצא", .devarim),
        ("Ki Tavo", "כי תבא", .devarim),
        ("Nitzavim", "נצבים", .devarim),
        ("Vayelech", "וילך", .devarim),
        ("Haazinu", "האזינו", .devarim),
        ("V'Zot HaBracha", "וזאת הברכה", .devarim)
    ]

    /// 1-indexed parasha by number.
    public static func parasha(_ index: Int) -> Parasha {
        let p = all[index - 1]
        return Parasha(
            index: index, name: p.name, hebrew: p.hebrew, book: p.book,
            doubleIndex: nil, doubleName: nil, doubleHebrew: nil
        )
    }

    /// Double parasha.
    public static func double(_ first: Int, _ second: Int) -> Parasha {
        let a = all[first - 1]
        let b = all[second - 1]
        return Parasha(
            index: first, name: a.name, hebrew: a.hebrew, book: a.book,
            doubleIndex: second, doubleName: b.name, doubleHebrew: b.hebrew
        )
    }

    /// Standard pairs that may be doubled (1-indexed first parasha of each pair).
    static let doublePairs: [(Int, Int)] = [
        (22, 23),  // Vayakhel-Pekudei
        (27, 28),  // Tazria-Metzora
        (29, 30),  // Acharei Mot-Kedoshim
        (32, 33),  // Behar-Bechukotai
        (39, 40),  // Chukat-Balak
        (42, 43),  // Matot-Masei
        (51, 52)   // Nitzavim-Vayelech
    ]
}

// MARK: - Schedule computation

public enum TorahReadings {

    /// Get the parasha for a specific Shabbat date.
    /// Returns nil if the date is not a Shabbat.
    public static func reading(
        for date: Date, timeZone: TimeZone = .current, israel: Bool
    ) -> WeeklyReading? {
        let hd = HebrewDate(from: date, timeZone: timeZone)
        guard hd.weekday == 7 else { return nil }

        let year = cycleYear(for: hd)
        let schedule = annualSchedule(year: year, israel: israel, timeZone: timeZone)
        return schedule.first { Calendar(identifier: .gregorian).isDate($0.date, inSameDayAs: date) }
    }

    /// Generate the full annual parasha schedule for a Hebrew year.
    /// The cycle runs from Simchat Torah of `year` to Simchat Torah of `year+1`.
    public static func annualSchedule(
        year: Int, israel: Bool, timeZone: TimeZone = .gmt
    ) -> [WeeklyReading] {
        var cal = Calendar(identifier: .hebrew)
        cal.timeZone = timeZone

        let simchatTorahDay = israel ? 22 : 23
        guard let simchatTorah = cal.date(
            from: DateComponents(year: year, month: 1, day: simchatTorahDay)
        ) else { return [] }

        guard let nextSimchatTorah = cal.date(
            from: DateComponents(year: year + 1, month: 1, day: simchatTorahDay)
        ) else { return [] }

        let shabbatBereishit = nextShabbat(after: simchatTorah, timeZone: timeZone)

        var shabbatot: [Date] = []
        var current = shabbatBereishit
        while current < nextSimchatTorah {
            shabbatot.append(current)
            current = current.addingTimeInterval(7 * 86400)
        }

        let holidayMap = buildHolidayMap(
            shabbatot: shabbatot, year: year, israel: israel, timeZone: timeZone
        )
        let availableCount = shabbatot.count - holidayMap.count
        let doublesNeeded = max(0, 53 - availableCount)
        let doubledFirstIndices = Set(
            ParashaList.doublePairs.prefix(doublesNeeded).map { $0.0 }
        )

        var result: [WeeklyReading] = []
        var parashaIndex = 1

        for shabbat in shabbatot {
            let hd = HebrewDate(from: shabbat, timeZone: timeZone)
            let special = detectSpecialShabbat(hd)

            if let holiday = holidayMap[shabbat] {
                result.append(WeeklyReading(
                    date: shabbat, hebrewDate: hd,
                    parasha: nil, holidayReading: holiday,
                    specialShabbat: special
                ))
            } else if parashaIndex <= 53 {
                let parasha: Parasha
                if doubledFirstIndices.contains(parashaIndex) {
                    let pair = ParashaList.doublePairs.first { $0.0 == parashaIndex }!
                    parasha = ParashaList.double(pair.0, pair.1)
                    parashaIndex += 2
                } else {
                    parasha = ParashaList.parasha(parashaIndex)
                    parashaIndex += 1
                }
                result.append(WeeklyReading(
                    date: shabbat, hebrewDate: hd,
                    parasha: parasha, holidayReading: nil,
                    specialShabbat: special
                ))
            }
        }

        return result
    }

    /// Which Hebrew year's reading cycle a given Hebrew date falls in.
    private static func cycleYear(for hd: HebrewDate) -> Int {
        if hd.month == 1 && hd.day <= (hd.isLeapYear ? 23 : 23) {
            let isIsrael = false
            let simchatDay = isIsrael ? 22 : 23
            if hd.day <= simchatDay { return hd.year - 1 }
        }
        return hd.year
    }

    // MARK: - Shabbat navigation

    private static func nextShabbat(after date: Date, timeZone: TimeZone) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        var current = cal.date(byAdding: .day, value: 1, to: date) ?? date
        while cal.component(.weekday, from: current) != 7 {
            current = cal.date(byAdding: .day, value: 1, to: current) ?? current
        }
        return cal.startOfDay(for: current)
    }

    // MARK: - Holiday Shabbat detection

    private static func buildHolidayMap(
        shabbatot: [Date], year: Int, israel: Bool, timeZone: TimeZone
    ) -> [Date: HolidayReading] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        var map: [Date: HolidayReading] = [:]

        for shabbat in shabbatot {
            let jd = JewishDay(from: shabbat, timeZone: timeZone, israel: israel)
            if let reading = holidayReadingFor(jd) {
                let key = cal.startOfDay(for: shabbat)
                map[key] = reading
            }
        }
        return map
    }

    // swiftlint:disable:next cyclomatic_complexity
    private static func holidayReadingFor(_ day: JewishDay) -> HolidayReading? {
        let m = day.month
        let d = day.day

        // Rosh Hashanah
        if day.isRoshHashanah {
            return d == 1 ? .roshHashanah1 : .roshHashanah2
        }
        // Yom Kippur
        if day.isYomKippur { return .yomKippur }
        // Sukkot YT
        if day.isSukkot {
            return d == 15 ? .sukkot1 : .sukkot2
        }
        // Chol HaMoed Sukkot (Shabbat)
        if day.isCholHamoedSukkot { return .cholHamoedSukkot }
        // Shemini Atzeret / Simchat Torah
        if day.isSheminiAtzeret { return .sheminiAtzeret }
        // Pesach
        if m == day.nisanMonthValue {
            if d == 15 { return .pesach1 }
            if d == 16 && !day.israel { return .pesach2 }
            if d == 21 { return .pesach7 }
            if d == 22 && !day.israel { return .pesach8 }
        }
        if day.isCholHamoedPesach { return .cholHamoedPesach }
        // Shavuot
        if day.isShavuot {
            let sivanM = day.isLeapYear ? 10 : 9
            return (m == sivanM && d == 6) ? .shavuot1 : .shavuot2
        }
        return nil
    }

    // MARK: - Special Shabbatot

    private static func detectSpecialShabbat(_ hd: HebrewDate) -> SpecialShabbat? {
        let leap = hd.isLeapYear
        let adarMonth = leap ? 7 : 6
        let nisanMonth = leap ? 8 : 7
        let avMonth = leap ? 12 : 11

        // Shabbat Shuvah: between RH and YK (3-9 Tishrei)
        if hd.month == 1 && (3...9).contains(hd.day) { return .shuvah }

        // Shabbat Shekalim: Shabbat before or on 1 Adar (Adar II in leap)
        if hd.month == adarMonth && hd.day <= 1 { return .shekalim }
        if hd.month == adarMonth - 1 && hd.day >= 25 {
            if daysUntilInMonth(from: hd.day, to: 1, currentMonth: hd.month, nextMonth: adarMonth) <= 6 {
                return .shekalim
            }
        }

        // Shabbat Zachor: Shabbat before Purim (14 Adar)
        if hd.month == adarMonth && (8...13).contains(hd.day) { return .zachor }

        // Shabbat Parah: 2 Shabbatot before 1 Nisan (the Shabbat before HaChodesh)
        if hd.month == adarMonth && hd.day >= 18 && hd.day <= 24 { return .parah }

        // Shabbat HaChodesh: Shabbat before or on 1 Nisan
        if hd.month == nisanMonth && hd.day == 1 { return .haChodesh }
        if hd.month == adarMonth && hd.day >= 25 { return .haChodesh }

        // Shabbat HaGadol: Shabbat before Pesach (8-14 Nisan)
        if hd.month == nisanMonth && (8...14).contains(hd.day) { return .haGadol }

        // Shabbat Chazon: Shabbat before Tisha B'Av
        if hd.month == avMonth && (2...8).contains(hd.day) { return .chazon }

        // Shabbat Nachamu: Shabbat after Tisha B'Av
        if hd.month == avMonth && (10...16).contains(hd.day) { return .nachamu }

        return nil
    }

    private static func daysUntilInMonth(
        from currentDay: Int, to targetDay: Int,
        currentMonth: Int, nextMonth: Int
    ) -> Int {
        var hcal = Calendar(identifier: .hebrew)
        hcal.timeZone = .gmt
        let daysInCurrent = 30
        return (daysInCurrent - currentDay) + targetDay
    }
}

// MARK: - JewishDay helper for nisan month access

extension JewishDay {
    var nisanMonthValue: Int { isLeapYear ? 8 : 7 }
}
