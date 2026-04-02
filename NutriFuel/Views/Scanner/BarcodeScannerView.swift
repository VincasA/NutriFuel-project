//
//  BarcodeScannerView.swift
//  NutriFuel
//

import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    let onScan: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var isTorchOn = false
    @State private var cameraPermission: AVAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationStack {
            ZStack {
                switch cameraPermission {
                case .authorized:
                    ScannerCameraView(onScan: { barcode in
                        onScan(barcode)
                    }, isTorchOn: $isTorchOn)
                    .ignoresSafeArea()

                    scannerOverlay

                case .denied, .restricted:
                    permissionDeniedView

                default:
                    ProgressView("Requesting Camera Access...")
                }
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if cameraPermission == .authorized {
                        Button(
                            isTorchOn ? "Turn Torch Off" : "Turn Torch On",
                            systemImage: isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill"
                        ) {
                            isTorchOn.toggle()
                        }
                        .labelStyle(.iconOnly)
                    }
                }
            }
            .task {
                await checkCameraPermission()
            }
        }
    }

    private var scannerOverlay: some View {
        VStack {
            Spacer()

            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.15, green: 0.76, blue: 0.50), lineWidth: 3)
                .frame(width: 280, height: 160)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.16))
                )

            Text("Point camera at barcode")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.top, 16)
                .shadow(radius: 4)

            Spacer()
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 14) {
            Image(systemName: "camera.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppStyle.subtleText)

            Text("Camera Access Denied")
                .font(.system(size: 22, weight: .bold, design: .rounded))

            Text("Enable camera access in iOS Settings to scan food barcodes.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppStyle.subtleText)

            Button("Open Settings") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                openURL(url)
            }
            .buttonStyle(.plain)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [AppStyle.accent, AppStyle.accentStrong],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
        }
        .padding(18)
        .appCardStyle()
        .padding(.horizontal, 20)
    }

    @MainActor
    private func checkCameraPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            cameraPermission = await AVCaptureDevice.requestAccess(for: .video) ? .authorized : .denied
        } else {
            cameraPermission = status
        }
    }
}

// MARK: - Camera UIViewController Wrapper

struct ScannerCameraView: UIViewControllerRepresentable {
    let onScan: (String) -> Void
    @Binding var isTorchOn: Bool

    func makeUIViewController(context: Context) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.onScan = onScan
        return vc
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        uiViewController.setTorch(on: isTorchOn)
    }
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onScan: ((String) -> Void)?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScanned = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let session = captureSession, !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let session = captureSession, session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                session.stopRunning()
            }
        }
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        captureSession = session

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            output.metadataObjectTypes = [
                .ean13, .ean8, .upce, .code128
            ]
        }

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        previewLayer = layer

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    func setTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
            // Torch toggle failed silently
        }
    }

    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadataObject = metadataObjects.first,
              let readable = metadataObject as? AVMetadataMachineReadableCodeObject,
              let barcode = readable.stringValue else { return }

        Task { @MainActor in
            guard !hasScanned else { return }
            hasScanned = true
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            captureSession?.stopRunning()
            onScan?(barcode)
        }
    }
}

#Preview {
    BarcodeScannerView { barcode in
        print("Scanned: \(barcode)")
    }
}
