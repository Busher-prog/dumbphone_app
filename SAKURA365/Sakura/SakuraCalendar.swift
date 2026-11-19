import Foundation

/// Maps a calendar date to the 365-petal system.
///
/// The tree always has exactly 365 day-blossoms, numbered 0…364 in the order
/// they fall. For any date:
///
/// * petals `0 ..< petalIndex` have fallen and lie beneath the tree,
/// * petal `petalIndex` is today's petal — it trembles, detaches and falls,
/// * petals `petalIndex + 1 ... 364` are still on the branches.
///
/// ### Leap years (366 days)
/// Every date keeps the *same* petal in every year, leap or not. February 29
/// has no petal of its own: on that day the tree "holds its breath" — the
/// February 28 petal keeps falling for a second day and nothing new detaches.
/// From March 1 onward the mapping is identical to a common year, and
/// December 31 is always the 365th (last) petal. The displayed counters
/// (“DAY 60 / 366”, days remaining, percentage) stay calendar-true.
struct SakuraDay: Equatable {
    /// 1-based ordinal of the date within its year (1…365 or 1…366).
    let dayOfYear: Int
    /// 365 or 366.
    let daysInYear: Int
    /// 0-based index of today's falling petal (0…364).
    let petalIndex: Int
    /// True on February 29.
    let isLeapDay: Bool

    static let petalCount = 365

    init(date: Date, calendar: Calendar = .current) {
        let ordinal = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let length = calendar.range(of: .day, in: .year, for: date)?.count ?? 365
        self.init(dayOfYear: ordinal, daysInYear: length)
    }

    init(dayOfYear: Int, daysInYear: Int) {
        let isLeapYear = daysInYear == 366
        // Feb 29 is ordinal 60 in a leap year (31 + 28 + 1).
        let leapDay = isLeapYear && dayOfYear == 60
        let index: Int
        if isLeapYear && dayOfYear >= 60 {
            // Feb 29 reuses Feb 28's petal (index 58); later days shift back by one.
            index = leapDay ? 58 : dayOfYear - 2
        } else {
            index = dayOfYear - 1
        }
        self.dayOfYear = dayOfYear
        self.daysInYear = daysInYear
        self.petalIndex = min(max(index, 0), Self.petalCount - 1)
        self.isLeapDay = leapDay
    }

    /// Petals already lying on the ground.
    var fallenCount: Int { petalIndex }
    /// Petals still attached (not counting today's falling petal).
    var remainingOnTree: Int { Self.petalCount - petalIndex - 1 }
    /// Calendar days left after today.
    var daysRemaining: Int { daysInYear - dayOfYear }
    /// Share of the year that has passed, including today.
    var progress: Double { Double(dayOfYear) / Double(daysInYear) }

    /// A quiet line for the day, chosen deterministically from the date.
    var reflection: String {
        if isLeapDay { return "A day between days. The tree holds its breath." }
        return Self.reflections[(dayOfYear - 1) % Self.reflections.count]
    }

    static let reflections = [
        "Every day is a petal in the wind.",
        "Nothing stays. Everything returns.",
        "The blossom does not hurry.",
        "Beauty lives in what is passing.",
        "Be still. The wind will come.",
        "One petal. One day. Enough.",
        "What falls becomes the ground.",
    ]
}
