//
//  CurlyQuoteAuditTests.swift
//  Compass
//
//  Created by Peter Milligan on 12/09/2025.
//

import XCTest

final class CurlyQuoteAuditTests: XCTestCase {

    // Characters we want to ban
    private static let badChars: [Character] = [
        "\"", // straight double quote is fine; but see below
        "“","”", // curly double quotes
        "‘","’", // curly single quotes
        "–","—"  // en/em dashes
    ]

    func test_noSmartQuotesOrDashesInSwiftSources() throws {
        let env = ProcessInfo.processInfo.environment
        let srcroot = env["SRCROOT"] ?? FileManager.default.currentDirectoryPath
        let root = URL(fileURLWithPath: srcroot)

        let folders = ["Compass", "CompassTests"]

        var hits: [String] = []

        for folder in folders {
            let dir = root.appendingPathComponent(folder)
            guard FileManager.default.fileExists(atPath: dir.path) else { continue }

            let enumerator = FileManager.default.enumerator(
                at: dir,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            )

            while let url = enumerator?.nextObject() as? URL {
                guard url.pathExtension == "swift" else { continue }
                guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }

                let lines = text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
                for (idx, lineSub) in lines.enumerated() {
                    let line = String(lineSub)
                    if line.contains(where: { Self.badChars.contains($0) }) {
                        let present = Self.badChars.filter { line.contains($0) }.map { String($0) }.joined()
                        hits.append("\(url.path):\(idx+1): contains [\(present)] → \(line)")
                    }
                }
            }
        }

        if !hits.isEmpty {
            XCTFail("Found smart quotes/dashes in Swift sources:\n" + hits.joined(separator: "\n"))
        }
    }
}
