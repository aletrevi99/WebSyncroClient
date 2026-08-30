import SwiftUI
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

/// Controller e View per fotocamera full-screen moderna e nativa con AVFoundation
#if os(iOS)
public struct ModernAVCameraView: View {
    public let onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    @StateObject private var cameraModel = CameraViewModel()
    @State private var flashMode: AVCaptureDevice.FlashMode = .auto

    public init(onImageCaptured: @escaping (UIImage) -> Void) {
        self.onImageCaptured = onImageCaptured
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Preview Video AVFoundation
            CameraPreviewRepresentable(session: cameraModel.session)
                .ignoresSafeArea()

            // Griglia Guida per Documenti
            VStack {
                Spacer()
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [8, 6]))
                    .frame(maxWidth: .infinity)
                    .aspectRatio(0.72, contentMode: .fit)
                    .padding(.horizontal, 24)
                    .overlay(
                        VStack {
                            HStack {
                                Text("Inquadra il foglio di carico")
                                    .font(.system(.caption, design: .rounded))
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                            .padding(.top, 16)
                            Spacer()
                        }
                    )
                Spacer()
            }

            // Controlli Superiori (Flash e Chiudi)
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }

                    Spacer()

                    Button(action: {
                        toggleFlash()
                    }) {
                        Image(systemName: flashIconName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(flashMode == .off ? .white.opacity(0.6) : .yellow)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // Barra di Scatto Inferiore
                HStack {
                    Spacer()

                    // Pulsante di Scatto Liquid Glass
                    Button(action: {
                        cameraModel.capturePhoto(flashMode: flashMode)
                    }) {
                        ZStack {
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 76, height: 76)

                            Circle()
                                .fill(Color.white)
                                .frame(width: 62, height: 62)
                        }
                    }
                    .disabled(cameraModel.isCapturing)
                    .scaleEffect(cameraModel.isCapturing ? 0.9 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: cameraModel.isCapturing)

                    Spacer()
                }
                .padding(.bottom, 36)
            }
        }
        .onAppear {
            cameraModel.checkPermissionsAndSetup()
        }
        .onDisappear {
            cameraModel.stopSession()
        }
        .onChange(of: cameraModel.capturedImage) { _, newImage in
            if let img = newImage {
                HapticFeedback.notification(.success)
                onImageCaptured(img)
                dismiss()
            }
        }
    }

    private var flashIconName: String {
        switch flashMode {
        case .auto: return "bolt.badge.automatic"
        case .on: return "bolt.fill"
        case .off: return "bolt.slash.fill"
        @unknown default: return "bolt.slash"
        }
    }

    private func toggleFlash() {
        HapticFeedback.selection()
        switch flashMode {
        case .auto: flashMode = .on
        case .on: flashMode = .off
        case .off: flashMode = .auto
        @unknown default: flashMode = .auto
        }
    }
}

// MARK: - Camera ViewModel (AVFoundation)

final class CameraViewModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var capturedImage: UIImage?
    @Published var isCapturing = false

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "it.websyncro.camera.sessionQueue")

    func checkPermissionsAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.setupSession()
                }
            }
        default:
            break
        }
    }

    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device),
                  self.session.canAddInput(input) else {
                self.session.commitConfiguration()
                return
            }

            self.session.addInput(input)

            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
                if #available(iOS 16.0, *) {
                    if let maxDim = self.photoOutput.supportedMaxPhotoDimensions.last {
                        self.photoOutput.maxPhotoDimensions = maxDim
                    }
                } else {
                    self.photoOutput.isHighResolutionCaptureEnabled = true
                }
            }

            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }

    func capturePhoto(flashMode: AVCaptureDevice.FlashMode) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async { self.isCapturing = true }

            let settings = AVCapturePhotoSettings()
            if self.photoOutput.supportedFlashModes.contains(flashMode) {
                settings.flashMode = flashMode
            }
            if #available(iOS 16.0, *) {
                if let maxDim = self.photoOutput.supportedMaxPhotoDimensions.last {
                    settings.maxPhotoDimensions = maxDim
                }
            } else {
                settings.isHighResolutionPhotoEnabled = true
            }

            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        DispatchQueue.main.async { self.isCapturing = false }
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            return
        }

        DispatchQueue.main.async {
            self.capturedImage = image
        }
    }
}

// MARK: - UIViewRepresentable Preview Layer

struct CameraPreviewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}

final class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
#else
public struct ModernAVCameraView: View {
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

