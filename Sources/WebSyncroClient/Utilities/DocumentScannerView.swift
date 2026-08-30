import SwiftUI
import Vision
#if canImport(VisionKit)
import VisionKit
#endif
#if canImport(PhotosUI)
import PhotosUI
#endif

/// Token di testo con coordinate spaziali 2D
public struct SpatialTextToken: Sendable {
    public let text: String
    public let boundingBox: CGRect // Coordinate normalizzate (0...1)
    public let midX: CGFloat
    public let midY: CGFloat

    public init(text: String, boundingBox: CGRect) {
        self.text = text
        self.boundingBox = boundingBox
        self.midX = boundingBox.midX
        self.midY = boundingBox.midY
    }
}

/// Gestore del riconoscimento testo OCR avanzato con ricostruzione tabellare 2D
public struct OCRManager {

    /// Riconosce il testo e ricostruisce la griglia tabellare 2D per righe orizzontali (da sinistra a destra)
    public static func recognizeText(from image: CGImage) async throws -> String {
        let tokens = try await recognizeSpatialTokens(from: image)
        return reconstructLines2D(from: tokens)
    }

    /// Estrae tutti i token spaziali con i loro bounding box
    public static func recognizeSpatialTokens(from image: CGImage) async throws -> [SpatialTextToken] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                var tokens: [SpatialTextToken] = []
                for obs in observations {
                    if let candidate = obs.topCandidates(1).first {
                        let str = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !str.isEmpty {
                            tokens.append(SpatialTextToken(text: str, boundingBox: obs.boundingBox))
                        }
                    }
                }

                continuation.resume(returning: tokens)
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["it-IT", "en-US"]
            request.usesLanguageCorrection = true
            // Supporto per il rilevamento di testo minimo e dettagliato in tabelle
            request.minimumTextHeight = 0.008

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Raggruppa i token che appartengono alla stessa riga orizzontale e li ordina da sinistra a destra
    public static func reconstructLines2D(from tokens: [SpatialTextToken], verticalThreshold: CGFloat = 0.014) -> String {
        guard !tokens.isEmpty else { return "" }

        // In Vision, y=0 è in basso e y=1 è in alto.
        // Ordiniamo prima dall'alto verso il basso (y decrescente)
        let sortedTokens = tokens.sorted { $0.midY > $1.midY }

        var lines: [[SpatialTextToken]] = []

        for token in sortedTokens {
            // Controlla se il token appartiene all'ultima riga aperta
            if let lastLine = lines.last, !lastLine.isEmpty {
                let averageY = lastLine.reduce(CGFloat(0)) { $0 + $1.midY } / CGFloat(lastLine.count)
                if abs(token.midY - averageY) <= verticalThreshold {
                    lines[lines.count - 1].append(token)
                    continue
                }
            }
            // Altrimenti inizia una nuova riga orizzontale
            lines.append([token])
        }

        // Per ogni riga orizzontale, ordina i token da sinistra a destra (x crescente)
        let formattedLines: [String] = lines.map { rowTokens in
            let sortedRow = rowTokens.sorted { $0.boundingBox.minX < $1.boundingBox.minX }
            return sortedRow.map { $0.text }.joined(separator: " ")
        }

        return formattedLines.joined(separator: "\n")
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
