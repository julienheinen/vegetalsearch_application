import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    @Binding var isTakingPicture: Bool
    @Binding var image: UIImage?

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)

        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium

        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            print("Failed to get the camera device")
            return view
        }

        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {
            print("Failed to create the camera input")
            return view
        }

        captureSession.addInput(input)

        let photoOutput = AVCapturePhotoOutput()
        photoOutput.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
        captureSession.addOutput(photoOutput)

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        captureSession.startRunning()

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        view.addGestureRecognizer(tapGesture)

        context.coordinator.captureSession = captureSession
        context.coordinator.photoOutput = photoOutput

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        let parent: CameraPreview
        var captureSession: AVCaptureSession!
        var photoOutput: AVCapturePhotoOutput!

        init(_ parent: CameraPreview) {
            self.parent = parent
        }

        @objc func handleTap() {
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .auto
            settings.isAutoStillImageStabilizationEnabled = true

            parent.isTakingPicture = true

            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
}

extension CameraPreview.Coordinator: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Failed to capture photo: \(error.localizedDescription)")
            parent.isTakingPicture = false
            return
        }

        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            print("Failed to convert photo data to UIImage")
            parent.isTakingPicture = false
            return
        }

        parent.image = image
        parent.isTakingPicture = false
    }
}
