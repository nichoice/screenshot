import CoreGraphics
import Foundation
import Vision

@MainActor
protocol OCRService {
    func recognizeText(in image: CGImage) async throws -> String
}

struct VisionOCRService: OCRService {
    func recognizeText(in image: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let lines = (request.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string }
                    .filter { !$0.isEmpty } ?? []
                continuation.resume(returning: lines.joined(separator: "\n"))
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            do {
                let handler = VNImageRequestHandler(cgImage: image, options: [:])
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
