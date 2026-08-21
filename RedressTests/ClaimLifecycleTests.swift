import XCTest
@testable import Redress

final class ClaimLifecycleTests: XCTestCase {

    // MARK: ClaimStatus

    func testTerminalStatuses() {
        XCTAssertTrue(ClaimStatus.paid.isTerminal)
        XCTAssertTrue(ClaimStatus.rejected.isTerminal)
        XCTAssertFalse(ClaimStatus.discovered.isTerminal)
        XCTAssertFalse(ClaimStatus.filed.isTerminal)
        XCTAssertFalse(ClaimStatus.underReview.isTerminal)
        XCTAssertFalse(ClaimStatus.appealPeriod.isTerminal)
    }

    func testAllStatusesHaveDisplayNames() {
        for status in ClaimStatus.allCases {
            XCTAssertFalse(status.displayName.isEmpty, "\(status) has an empty display name")
        }
    }

    // MARK: Claim defaults

    func testNewClaimStartsDiscoveredWithNoDocuments() {
        let claim = Claim(settlementID: "sample-001", settlementTitle: "Test Settlement")
        XCTAssertEqual(claim.status, .discovered)
        XCTAssertTrue(claim.documentFileNames.isEmpty)
        XCTAssertNil(claim.estimatedPayout)
        XCTAssertNil(claim.actualPayout)
        XCTAssertNil(claim.filedDate)
    }

    func testStatusRoundTripsThroughRawValue() {
        let claim = Claim(settlementID: "sample-001", settlementTitle: "Test Settlement")
        claim.status = .paid
        XCTAssertEqual(claim.statusRaw, "paid")
        XCTAssertEqual(claim.status, .paid)
    }

    func testUnknownRawStatusFallsBackToDiscovered() {
        let claim = Claim(settlementID: "sample-001", settlementTitle: "Test Settlement")
        claim.statusRaw = "not-a-real-status"
        XCTAssertEqual(claim.status, .discovered)
    }

    // MARK: ProofRequirement

    func testAllProofRequirementsHaveSummaries() {
        for requirement in ProofRequirement.allCases {
            XCTAssertFalse(requirement.summary.isEmpty, "\(requirement) has an empty summary")
        }
    }

    func testUnknownRawProofRequirementFallsBackToNone() {
        let settlement = Settlement(
            id: "test",
            title: "Test",
            brand: "Test Brand",
            settlementDescription: "desc",
            eligibilityCriteria: "criteria",
            proofRequirement: .strictProof,
            administratorName: "Admin",
            administratorPortalURLString: "https://example.com",
            claimDeadline: Date(),
            isSampleData: true
        )
        settlement.proofRequirementRaw = "not-a-real-requirement"
        XCTAssertEqual(settlement.proofRequirement, .none)
    }
}
