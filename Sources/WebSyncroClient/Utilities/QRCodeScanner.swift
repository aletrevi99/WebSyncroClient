import SwiftUI
import AVFoundation

/// Parser per il contenuto scansionato dal codice QR del mercatino
public struct QRCodeParser {
    public struct ScannedAccount: Equatable {
        public let rawShop: String
        public let cardCode: String
        public let pin: String
    }

    /// Analizza il codice QR nel formato standard: "NomeNegozio/CodiceTessera/PIN"
    public static func parse(qrString: String) -> ScannedAccount? {
        let trimmed = qrString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Divisione per slash '/'
        var parts = trimmed.components(separatedBy: "/")
        if parts.count < 3 {
            // Tentativo con pipe '|' o trattino basso '_'
            if trimmed.contains("|") {
                parts = trimmed.components(separatedBy: "|")
            }
        }

        guard parts.count >= 3 else {
            return nil
        }

        let shop = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let card = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
        let pin = parts[2].trimmingCharacters(in: .whitespacesAndNewlines)

        guard !shop.isEmpty && !card.isEmpty && !pin.isEmpty else {
            return nil
        }

        return ScannedAccount(rawShop: shop, cardCode: card, pin: pin)
    }
}

#if os(iOS)
/// Vista camera nativa per scansione rapida di codici QR
public struct QRCodeScannerView: UIViewControllerRepresentable {
    public let onScanned: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    public init(onScanned: @escaping (String) -> Void) {
        self.onScanned = onScanned
    }

    public func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    public func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public class Coordinator: NSObject, ScannerViewControllerDelegate {
        let parent: QRCodeScannerView
        private var hasScanned = false

        init(parent: QRCodeScannerView) {
            self.parent = parent
        }

        func didFindCode(_ code: String) {
            guard !hasScanned else { return }
            hasScanned = true
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            parent.onScanned(code)
            parent.dismiss()
        }
    }
}

protocol ScannerViewControllerDelegate: AnyObject {
    func didFindCode(_ code: String)
}

public class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: ScannerViewControllerDelegate?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            showFailedAlert(title: "Fotocamera non supportata", message: "Questo dispositivo non ha una fotocamera disponibile.")
            return
        }

        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            showFailedAlert(title: "Errore Fotocamera", message: "Impossibile accedere alla fotocamera.")
            return
        }

        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            showFailedAlert(title: "Errore Configurazione", message: "Impossibile aggiungere l'input video.")
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            showFailedAlert(title: "Errore Configurazione", message: "Impossibile configurare l'output di scansione QR.")
            return
        }

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.layer.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        self.previewLayer = preview
        self.captureSession = session

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
    }

    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else { return }

        delegate?.didFindCode(stringValue)
    }

    private func showFailedAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
#else
public struct QRCodeScannerView: View {
    public let onScanned: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    public init(onScanned: @escaping (String) -> Void) {
        self.onScanned = onScanned
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text("Scansione QR non disponibile su macOS")
                .font(.headline)
            Button("Chiudi") {
                dismiss()
            }
        }
        .padding()
    }
}
#endif
