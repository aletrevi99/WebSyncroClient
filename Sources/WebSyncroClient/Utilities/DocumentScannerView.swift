import SwiftUI
import Vision
#if canImport(VisionKit)
import VisionKit
#endif
#if canImport(PhotosUI)
import PhotosUI
#endif

/// Gestore del riconoscimento testo OCR basato sul framework nativo Apple Vision (Neural Engine on-device)
public struct OCRManager {
    public static func recognizeText(from image: CGImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                let fullText = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: fullText)
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["it-IT", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

#if os(iOS)
/// Scanner fotocamera nativo Apple per documenti con auto-ritaglio e correzione prospettica
public struct DocumentCameraScannerView: UIViewControllerRepresentable {
    public let onScanned: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    public init(onScanned: @escaping (UIImage) -> Void) {
        self.onScanned = onScanned
    }

    public func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    public func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentCameraScannerView

        init(parent: DocumentCameraScannerView) {
            self.parent = parent
        }

        public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            guard scan.pageCount > 0 else {
                parent.dismiss()
                return
            }
            let firstPage = scan.imageOfPage(at: 0)
            parent.onScanned(firstPage)
            parent.dismiss()
        }

        public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }

        public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            parent.dismiss()
        }
    }
}
#else
public struct DocumentCameraScannerView: View {
    public let onScanned: (Any) -> Void
    @Environment(\.dismiss) private var dismiss

    public init(onScanned: @escaping (Any) -> Void) {
        self.onScanned = onScanned
    }

    public var body: some View {
        VStack {
            Text("Scanner fotocamera non disponibile su macOS.")
            Button("Chiudi") { dismiss() }
        }
        .padding()
    }
}
#endif
