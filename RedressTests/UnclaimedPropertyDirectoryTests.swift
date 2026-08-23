import XCTest
@testable import Redress

final class UnclaimedPropertyDirectoryTests: XCTestCase {

    func testEveryURLStringParses() {
        for source in UnclaimedPropertyDirectory.sources {
            XCTAssertNotNil(source.url, "\(source.state)'s URL string failed to parse: \(source.urlString)")
        }
    }

    func testNoDuplicateStates() {
        let states = UnclaimedPropertyDirectory.sources.map(\.state)
        XCTAssertEqual(states.count, Set(states).count, "a state appears more than once")
    }

    func testCoversAllFiftyStatesAndDC() {
        // 50 states + DC, plus whatever territories are confirmed live —
        // this is a floor, not an exact count, so adding a territory later
        // doesn't break this test.
        XCTAssertGreaterThanOrEqual(UnclaimedPropertyDirectory.sources.count, 51)
    }

    func testSortedAlphabeticallyByState() {
        let states = UnclaimedPropertyDirectory.sources.map(\.state)
        XCTAssertEqual(states, states.sorted(), "list should already be alphabetical for display")
    }
}
