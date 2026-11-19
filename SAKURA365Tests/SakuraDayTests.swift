import XCTest
@testable import SAKURA365

final class SakuraDayTests: XCTestCase {
    private func day(_ y: Int, _ m: Int, _ d: Int) -> SakuraDay {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let date = cal.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
        return SakuraDay(date: date, calendar: cal)
    }

    func testCommonYearBounds() {
        XCTAssertEqual(day(2026, 1, 1).petalIndex, 0)
        XCTAssertEqual(day(2026, 1, 1).fallenCount, 0)
        XCTAssertEqual(day(2026, 12, 31).petalIndex, 364)
        XCTAssertEqual(day(2026, 12, 31).remainingOnTree, 0)
        XCTAssertEqual(day(2026, 11, 19).dayOfYear, 323)
        XCTAssertEqual(day(2026, 11, 19).daysRemaining, 42)
    }

    func testLeapYearKeepsSamePetalPerDate() {
        XCTAssertEqual(day(2028, 2, 28).petalIndex, day(2027, 2, 28).petalIndex)
        XCTAssertEqual(day(2028, 3, 1).petalIndex, day(2027, 3, 1).petalIndex)
        XCTAssertEqual(day(2028, 12, 31).petalIndex, 364)
        XCTAssertEqual(day(2028, 12, 31).daysInYear, 366)
    }

    func testLeapDayHoldsBreath() {
        let leap = day(2028, 2, 29)
        XCTAssertTrue(leap.isLeapDay)
        XCTAssertEqual(leap.petalIndex, day(2028, 2, 28).petalIndex)
        XCTAssertEqual(leap.dayOfYear, 60)
    }

    func testEveryDateMapsIntoRange() {
        for year in [2026, 2028] {
            let length = year == 2028 ? 366 : 365
            var previous = -1
            for ordinal in 1...length {
                let d = SakuraDay(dayOfYear: ordinal, daysInYear: length)
                XCTAssert((0..<365).contains(d.petalIndex))
                XCTAssert(d.petalIndex == previous || d.petalIndex == previous + 1)
                previous = d.petalIndex
            }
            XCTAssertEqual(previous, 364)
        }
    }

    func testTreeIsDeterministic() {
        let tree = SakuraTree.shared
        XCTAssertEqual(tree.blossoms.count, 365)
        XCTAssertEqual(Set(tree.fallOrder).count, 365)
        // Same seed, same first draws — positions never regenerate between launches.
        var a = Mulberry32(seed: SakuraTree.seed), b = Mulberry32(seed: SakuraTree.seed)
        for _ in 0..<100 { XCTAssertEqual(a.next(), b.next()) }
    }
}
