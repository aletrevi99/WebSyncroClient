import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(PDFKit)
import PDFKit
#endif
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

// MARK: - Convertitore PDF in Immagine ad Alta Risoluzione

public struct PDFImageConverter {
    #if os(iOS)
    public static func renderPDFPageToImage(data: Data, pageIndex: Int = 0, scale: CGFloat = 2.0) -> UIImage? {
        #if canImport(PDFKit)
        guard let document = PDFDocument(data: data),
              let page = document.page(at: pageIndex) else {
            return nil
        }

        let pageRect = page.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: pageRect.width * scale, height: pageRect.height * scale))

        let image = renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: pageRect.width * scale, height: pageRect.height * scale)))

            ctx.cgContext.saveGState()
            ctx.cgContext.scaleBy(x: scale, y: scale)
            ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
            page.draw(with: .mediaBox, to: ctx.cgContext)
            ctx.cgContext.restoreGState()
        }

        return image
        #else
        return nil
        #endif
    }
    #else
    public static func renderPDFPageToImage(data: Data, pageIndex: Int = 0, scale: CGFloat = 2.0) -> Any? {
        return nil
    }
    #endif
}

// MARK: - Fotocamera Nativa Punta e Scatta (1-Tap Snap & Go)

#if os(iOS)
public struct SimpleCameraView: UIViewControllerRepresentable {
    public let onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    public init(onImageCaptured: @escaping (UIImage) -> Void) {
        self.onImageCaptured = onImageCaptured
    }

    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
        } else {
            picker.sourceType = .photoLibrary
        }
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: SimpleCameraView

        init(parent: SimpleCameraView) {
            self.parent = parent
        }

        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            parent.dismiss()
        }

        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
#else
public struct SimpleCameraView: View {
    public let onImageCaptured: (Any) -> Void
    @Environment(\.dismiss) private var dismiss

    public init(onImageCaptured: @escaping (Any) -> Void) {
        self.onImageCaptured = onImageCaptured
    }

    public var body: some View {
        VStack {
            Text("Fotocamera non disponibile su macOS.")
            Button("Chiudi") { dismiss() }
        }
    }
}
#endif

// MARK: - Selettore File / Documenti (Supporto PDF e Immagini)

#if os(iOS)
public struct FileDocumentPickerView: UIViewControllerRepresentable {
    public let onDocumentSelected: (Data, String) -> Void
    @Environment(\.dismiss) private var dismiss

    public init(onDocumentSelected: @escaping (Data, String) -> Void) {
        self.onDocumentSelected = onDocumentSelected
    }

    public func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.pdf, .image, .jpeg, .png]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    public func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: FileDocumentPickerView

        init(parent: FileDocumentPickerView) {
            self.parent = parent
        }

        public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            let isAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if isAccessing { url.stopAccessingSecurityScopedResource() }
            }

            if let data = try? Data(contentsOf: url) {
                parent.onDocumentSelected(data, url.lastPathComponent)
            }
            parent.dismiss()
        }

        public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}
#else
public struct FileDocumentPickerView: View {
    public let onDocumentSelected: (Data, String) -> Void
    @Environment(\.dismiss) private var dismiss

    public init(onDocumentSelected: @escaping (Data, String) -> Void) {
        self.onDocumentSelected = onDocumentSelected
    }

    public var body: some View {
        VStack {
            Text("File picker non disponibile su macOS.")
            Button("Chiudi") { dismiss() }
        }
    }
}
#endif
