import SwiftUI
#if canImport(CoreImage)
import CoreImage
#endif
#if canImport(UIKit)
import UIKit
#endif

public enum BarcodeGenerator {
    /// Genera un'immagine ad alta risoluzione del codice a barre Code 128
    public static func generateCode128(from string: String) -> Image? {
        #if canImport(UIKit) && canImport(CoreImage)
        guard let data = string.data(using: .ascii) else { return nil }
        guard let filter = CIFilter(name: "CICode128BarcodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(7.0, forKey: "inputQuietSpace")

        guard let outputImage = filter.outputImage else { return nil }

        // Ingrandimento con interpolazione nearest-neighbor per preservare la nitidezza del barcode
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)

        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        let uiImage = UIImage(cgImage: cgImage)
        return Image(uiImage: uiImage)
        #else
        return nil
        #endif
    }
}
