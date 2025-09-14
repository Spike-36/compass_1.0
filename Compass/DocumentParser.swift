import Foundation

public struct ParsedSentence {
    public let id: String
    public let text: String
    public let blockType: String?   // e.g. "answer", "stat"
    public let blockNumber: String? // e.g. "5"
}

public enum DocumentParser {
    /// Parses a list of raw lines into structured sentences with block context.
    public static func parse(_ lines: [String]) -> [ParsedSentence] {
        var results: [ParsedSentence] = []
        var currentBlockType: String? = nil
        var currentBlockNumber: String? = nil
        var counter = 0

        for line in lines {
            switch BlockHeaderDetector.classify(line) {
            case .header(let type, let number, _):
                // Update block context, don’t emit as a sentence
                currentBlockType = type
                currentBlockNumber = number

            case .body(let text):
                let sentences = SentenceSplitter.split(text)
                for sentence in sentences {
                    counter += 1
                    let id = makeID(blockType: currentBlockType,
                                    blockNumber: currentBlockNumber,
                                    counter: counter)
                    results.append(
                        ParsedSentence(
                            id: id,
                            text: sentence,
                            blockType: currentBlockType,
                            blockNumber: currentBlockNumber
                        )
                    )
                }
            }
        }
        return results
    }

    private static func makeID(blockType: String?, blockNumber: String?, counter: Int) -> String {
        var parts: [String] = []
        if let type = blockType { parts.append(type) }
        if let num = blockNumber { parts.append(num) }
        parts.append(String(counter))
        return parts.joined(separator: "-")
    }
}
//
//  DocumentParser.swift
//  Compass
//
//  Created by Peter Milligan on 13/09/2025.
//

