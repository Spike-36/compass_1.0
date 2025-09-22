//
//  DocxImportManager.swift
//  Compass
//

import Foundation

struct DocxImportManager {
    static func handleImport(url: URL, completion: @escaping (String) -> Void) {
        ConversionTask.run(with: url) { result in
            switch result {
            case .success(let message):
                let baseName = url.deletingPathExtension().lastPathComponent

                // ---- Ensure exports directory exists ----
                let exportsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("exports", isDirectory: true)
                try? FileManager.default.createDirectory(at: exportsDir, withIntermediateDirectories: true)

                // ---- Debug: print resolved sandbox path ----
                print("📂 Exports directory resolved to: \(exportsDir.path)")

                // ---- 1. PDF handoff ----
                let pdfURL = exportsDir.appendingPathComponent("\(baseName).pdf")
                print("📢 Posting OpenConvertedPDF for \(pdfURL.path)")

                NotificationCenter.default.post(
                    name: .OpenConvertedPDF,
                    object: nil,
                    userInfo: ["url": pdfURL]
                )

                // ---- 2. JSON handoff ----
                let jsonURL = exportsDir.appendingPathComponent("\(baseName).capture.json")

                if FileManager.default.fileExists(atPath: jsonURL.path) {
                    do {
                        let records = try loadCaptureJSON(from: jsonURL)
                        print("✅ Loaded \(records.count) CaptureRecords from \(jsonURL.lastPathComponent)")
                        for (idx, rec) in records.prefix(5).enumerated() { // show first 5 for sanity
                            print("   [\(idx+1)] \(rec.block_type)#\(rec.block_number).\(rec.sentence_index): \(rec.text.prefix(60))")
                        }
                        if records.count > 5 {
                            print("   … (\(records.count - 5) more)")
                        }
                    } catch {
                        print("⚠️ Failed to decode \(jsonURL.lastPathComponent): \(error)")
                    }
                } else {
                    print("⚠️ No capture.json found at \(jsonURL.path)")
                }

                completion(message)

            case .failure(let error):
                completion("❌ Conversion failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - JSON Loader

    private static func loadCaptureJSON(from url: URL) throws -> [CaptureRecord] {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode([CaptureRecord].self, from: data)
    }
}

