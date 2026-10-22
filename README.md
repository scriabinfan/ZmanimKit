# ZmanimKit

A pure-Swift library for Jewish calendar calculations, halachic times (zmanim), and holiday detection. Zero external dependencies — fully offline.

## Features

- **Solar Calculator** — NOAA algorithm for sunrise, sunset, solar noon, and arbitrary sun-angle times at any latitude/longitude
- **Zmanim Calculator** — All standard halachic times: Alot HaShachar, Misheyakir, latest Shema and Shacharit, Chatzot, Mincha Gedola/Ketana, Plag HaMincha, nightfall, candle lighting
- **Multiple timing methods** — GRA (Vilna Gaon), MGA fixed-72, MGA 16.1°, and Baal HaTanya
- **Hebrew Calendar** — Date conversion with proper month names (English and Hebrew), Hebrew numerals, leap year handling, sunset-aware religious date boundaries
- **Jewish Calendar** — Complete holiday and occasion detection with Israel/Diaspora divergence, fast postponement, Hallel type, Rosh Chodesh, Chol HaMoed, rain mention/request tracking
- **Annual holiday list** — Generate all holidays for any Hebrew year
- **Polar handling** — Explicit unavailable state at extreme latitudes (no fabricated times)

## Requirements

- Swift 5.9+
- iOS 17+ / macOS 14+ / watchOS 10+ / tvOS 17+

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/andreboiko/ZmanimKit.git", from: "0.1.0")
]
```

## Usage

### Zmanim (Halachic Times)

```swift
import ZmanimKit

let calc = ZmanimCalculator(
    latitude: 31.7683,
    longitude: 35.2137,
    timeZone: TimeZone(identifier: "Asia/Jerusalem")!
)

let today = calc.zmanim(for: Date(), method: .gra)

if let sunrise = today.sunrise {
    print("Sunrise: \(sunrise)")
}
if let shema = today.latestShema {
    print("Latest Shema (GRA): \(shema)")
}
if let candles = calc.candleLighting(for: fridayDate, minutesBefore: 18) {
    print("Candle lighting: \(candles)")
}

// All times sorted with labels
for entry in today.entries {
    print("\(entry.label) (\(entry.hebrew)): \(entry.time)")
}
```

### Hebrew Dates

```swift
let hebrewDate = HebrewDate(from: Date(), timeZone: .current)
print(hebrewDate.formatted)        // "15 Tishrei 5787"
print(hebrewDate.formattedHebrew)  // "ט״ו תשרי תשפ״ז"
print(hebrewDate.monthName)        // "Tishrei"

// Sunset-aware religious date
let religiousDate = HebrewDate.religiousDate(
    at: now, sunset: sunsetTime, timeZone: localTZ
)
```

### Jewish Calendar

```swift
let day = JewishDay(from: Date(), timeZone: .current, israel: false)

if day.isChanukah { print("Happy Chanukah!") }
if day.isRoshChodesh { print("Rosh Chodesh") }
if let fast = day.minorFast { print(fast.displayName) }
if let hallel = day.hallelType { print("\(hallel) Hallel") }

// All active occasions
let occasions = day.occasions  // Set<JewishOccasion>

// Summary labels
for label in day.summary { print(label) }

// Annual holiday list
let holidays = JewishHolidays.holidays(year: 5787, israel: false)
```

### Timing Methods

| Method | Day boundaries | Source |
|--------|---------------|--------|
| GRA | Sunrise to sunset | Vilna Gaon |
| MGA (72 min) | Sunrise−72 to sunset+72 | Magen Avraham |
| MGA (16.1°) | Dawn 16.1° to nightfall 16.1° | Magen Avraham (angular) |
| Baal HaTanya | Dawn 16.9° to nightfall 8.5° | Shulchan Aruch HaRav |

## Solar Algorithm

Uses the NOAA Solar Calculator algorithm (public domain), which computes solar position from Julian dates, orbital eccentricity, equation of time, and solar declination. Accurate to within ~1 minute for standard latitudes.

## Halachic Notes

- This library computes astronomical times and calendar facts. It does not make halachic decisions.
- Named timing methods reflect documented computational approaches, not authoritative rulings.
- Consult your local Orthodox authority for practical observance questions.
- Polar and extreme-latitude locations return explicit unavailable states rather than fabricated times.

## License

MIT License. See [LICENSE](LICENSE).
