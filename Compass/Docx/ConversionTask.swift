// ConversionTask.swift
import Foundation

enum ConversionError: Error {
    case failed
}

struct ConversionTask {
    static func run(with url: URL, completion: @escaping (Result<String, Error>) -> Void) {
        // Ensure ~/Documents/exports exists inside the app sandbox
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let outputDir = documentsDir.appendingPathComponent("exports")
        try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        // Path to LibreOffice binary
        let sofficePath = "/Applications/LibreOffice.app/Contents/MacOS/soffice"

        // Launch LibreOffice in headless mode to convert
        let process = Process()
        process.executableURL = URL(fileURLWithPath: sofficePath)
        process.arguments = [
            "--headless",
            "--convert-to", "pdf",
            "--outdir", outputDir.path,
            url.path
        ]

        let pipe = Pipe()
        process.standardError = pipe
        process.standardOutput = pipe

        do {
            try process.run()

            process.terminationHandler = { process in
                if process.terminationStatus == 0 {
                    let pdfURL = outputDir.appendingPathComponent(
                        url.deletingPathExtension().lastPathComponent + ".pdf"
                    )

                    DispatchQueue.main.async {
                        print("✅ ConversionTask finished writing PDF to \(pdfURL.path)")
                        print("📢 Posting OpenConvertedPDF for \(pdfURL.path)")

                        NotificationCenter.default.post(
                            name: .OpenConvertedPDF,
                            object: nil,
                            userInfo: ["url": pdfURL]
                        )

                        let message = "✅ Exported to \(pdfURL.path)"
                        completion(.success(message))
                    }
                } else {
                    let errorMsg = String(
                        data: pipe.fileHandleForReading.readDataToEndOfFile(),
                        encoding: .utf8
                    ) ?? "Unknown error"
                    DispatchQueue.main.async {
                        completion(.failure(NSError(
                            domain: "ConversionTask",
                            code: Int(process.terminationStatus),
                            userInfo: [NSLocalizedDescriptionKey: errorMsg]
                        )))
                    }
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
}

