import XCTest
@testable import Compass

final class DBTests: XCTestCase {

    func testLinkInsertAndFetch() {
        let db = DB.shared
        XCTAssertTrue(db.insertLink(statementId: 2150, responseId: 2196))
        
        let links = db.fetchLinks(forStatement: 2150)
        XCTAssertFalse(links.isEmpty)
        
        print("Links:", links)
    }
}

