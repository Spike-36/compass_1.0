import Foundation

/// Container for HTML export results and some basic counts.
public struct HTMLExportResult {
    public let html: String
    public let anchors: [String]
    public let paraCount: Int
    public let sentCount: Int
    public let htmlURL: URL

    public init(html: String,
                anchors: [String] = [],
                paraCount: Int = 0,
                sentCount: Int = 0,
                htmlURL: URL? = nil) {

        self.html = html
        self.anchors = anchors
        self.paraCount = paraCount
        self.sentCount = sentCount
        self.htmlURL = htmlURL ?? URL(fileURLWithPath: "/tmp/demo.html")
    }
}

