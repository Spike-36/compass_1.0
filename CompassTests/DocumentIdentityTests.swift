import XCTest
@testable import Compass

final class DocumentIdentityTests: XCTestCase {

    // 1. Regex: IDs must be "doc-para-sent"
    func testSentenceIdRegex() throws {
        let regex = try! NSRegularExpression(pattern: #"^doc\d+-para\d+-sent\d+$"#)

        let good = "doc1-para2-sent3"
        let bad = "doc-para-sentence"

        XCTAssertNotNil(regex.firstMatch(in: good, range: NSRange(location: 0, length: good.utf16.count)))
        XCTAssertNil(regex.firstMatch(in: bad, range: NSRange(location: 0, length: bad.utf16.count)))
    }

    // 2. Timestamp: must end in Z
    func testTimestampsEndWithZ() {
        let good = "2025-09-17T07:50:00Z"
        let bad = "2025-09-17T07:50:00+01:00"

        XCTAssertTrue(good.hasSuffix("Z"))
        XCTAssertFalse(bad.hasSuffix("Z"))
    }

    // 3. Concurrency: stale update → 409
    func testOptimisticConcurrencyConflict() async {
        // Pseudocode: replace with real call to your network/service layer
        let service = MockSentenceService()

        // Insert baseline
        let original = Sentence(id: "doc1-para1-sent1", updatedAt: "2025-09-17T07:50:00Z")
        service.store(original)

        // Try to update with old timestamp
        let staleUpdate = Sentence(id: "doc1-para1-sent1", updatedAt: "2025-09-17T07:40:00Z")

        do {
            try await service.update(staleUpdate)
            XCTFail("Expected 409 conflict")
        } catch let error as ServiceError {
            XCTAssertEqual(error, .conflict409)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// --- Mock scaffolding for now ---

struct Sentence {
    let id: String
    let updatedAt: String
}

enum ServiceError: Error, Equatable {
    case conflict409
}

actor MockSentenceService {
    private var storeDict: [String: String] = [:] // id → updatedAt

    func store(_ s: Sentence) {
        storeDict[s.id] = s.updatedAt
    }

    func update(_ s: Sentence) async throws {
        guard let current = storeDict[s.id] else {
            storeDict[s.id] = s.updatedAt
            return
        }
        if current != s.updatedAt {
            throw ServiceError.conflict409
        }
        // else: accept update
        storeDict[s.id] = s.updatedAt
    }
}
