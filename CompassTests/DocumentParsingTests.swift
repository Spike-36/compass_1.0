import XCTest
@testable import Compass

final class DocumentParsingTests: XCTestCase {

    func testPipeline_runs_end_to_end() throws {
        let fm = FileManager.default
        let tmp = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let docs = tmp.appendingPathComponent("docs")
        let json = tmp.appendingPathComponent("json")
        try fm.createDirectory(at: docs, withIntermediateDirectories: true)
        try fm.createDirectory(at: json, withIntermediateDirectories: true)

        let sample = """
        The defendant admits the signature. The notice is disputed.

        The claimant says the value is high. It is contested.
        """
        let file = docs.appendingPathComponent("PleadingA.docx")
        try sample.data(using: .utf8)!.write(to: file)

        // 1) identity + manifest shell
        let id = try IdentityBuilder.build(for: file, jsonRoot: json, type: "docx")
        XCTAssertEqual(id.type, "docx")
        XCTAssertEqual(id.docID, "pleadinga")
        XCTAssertGreaterThanOrEqual(id.version, 1)

        // 2) paragraphs (naive text semanticizer)
        let sem = NaiveTextSemanticizer()
        let paragraphs = try sem.paragraphs(from: file)
        XCTAssertEqual(paragraphs.count, 2)

    
        // 3) export HTML + anchors
        // (rest of test code here)
    }   // closes the function

}       // closes the class
