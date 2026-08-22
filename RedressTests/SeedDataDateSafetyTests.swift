import XCTest
@testable import Redress

/// Regression guard: a date stamped "T00:00:00Z" (midnight UTC) displays as
/// the PREVIOUS day once rendered in any timezone behind UTC — confirmed
/// live 2026-08-21 in EDT (UTC-4), where a real Aug 20 filing date and an
/// Aug 21 source-verification date both displayed one day early. Every
/// date-only fact in the bundled seed data should be stamped at noon UTC
/// instead, which is safe across the full range of real-world timezones.
final class SeedDataDateSafetyTests: XCTestCase {

    private func jsonStrings(in resource: String) throws -> [String] {
        guard let url = Bundle(for: Self.self).url(forResource: resource, withExtension: "json")
            ?? Bundle.main.url(forResource: resource, withExtension: "json") else {
            throw XCTSkip("\(resource).json not found in test bundle — skipping rather than failing the whole suite")
        }
        let data = try Data(contentsOf: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("\(resource).json did not decode as a JSON object")
            return []
        }
        return Self.allStrings(in: json)
    }

    private static func allStrings(in value: Any) -> [String] {
        switch value {
        case let string as String:
            return [string]
        case let array as [Any]:
            return array.flatMap { allStrings(in: $0) }
        case let dict as [String: Any]:
            return dict.values.flatMap { allStrings(in: $0) }
        default:
            return []
        }
    }

    func testNoMidnightUTCTimestampsInSettlementSeed() throws {
        let strings = try jsonStrings(in: "SeedSettlements")
        let midnightStamps = strings.filter { $0.hasSuffix("T00:00:00Z") }
        XCTAssertTrue(midnightStamps.isEmpty,
                       "Found midnight-UTC date(s) that will display as the wrong day in western timezones: \(midnightStamps)")
    }

    func testNoMidnightUTCTimestampsInWatchlistSeed() throws {
        let strings = try jsonStrings(in: "WatchlistCases")
        let midnightStamps = strings.filter { $0.hasSuffix("T00:00:00Z") }
        XCTAssertTrue(midnightStamps.isEmpty,
                       "Found midnight-UTC date(s) that will display as the wrong day in western timezones: \(midnightStamps)")
    }
}
