import SwiftUI
import Combine
import AVFoundation

// MARK: - Camera Preview Engine
// This bridges the iOS Camera Layer to SwiftUI
struct CameraPreview: UIViewRepresentable {
    @Binding var isFrontCamera: Bool
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        setupSession(view: view)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        setupSession(view: uiView)
    }
    
    private func setupSession(view: UIView) {
        let session = AVCaptureSession()
        session.beginConfiguration()
        
        // Remove existing inputs to allow switching
        session.inputs.forEach { session.removeInput($0) }
        
        let position: AVCaptureDevice.Position = isFrontCamera ? .front : .back
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        // Setup the visual layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        
        view.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        view.layer.addSublayer(previewLayer)
        
        session.commitConfiguration()
        
        // Start the camera on a background thread
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
}

final class AgoraCallManager: ObservableObject {
    @Published var isJoined = false
    @Published var isMuted = false
    @Published var isVideoEnabled = true
    @Published var isInCall = false

    func setup() {
        // Request camera permissions
        AVCaptureDevice.requestAccess(for: .video) { _ in }
    }

    func join() {
        self.isInCall = true
        self.isJoined = true
    }

    func leave() {
        self.isInCall = false
        self.isJoined = false
    }

    func toggleMute() { isMuted.toggle() }
    func toggleVideo() { isVideoEnabled.toggle() }
}

struct CallsView: View {
    @StateObject private var manager = AgoraCallManager()
    @State private var passcode: String = ""
    @State private var showConnectDialog = false
    @State private var isFrontCamera = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if manager.isInCall {
                    ZStack {
                        // --- FIX: Real Camera Feed ---
                        if manager.isVideoEnabled {
                            CameraPreview(isFrontCamera: $isFrontCamera)
                                .ignoresSafeArea()
                        } else {
                            videoOffPlaceholder
                        }
                        
                        // Controls Overlay
                        VStack {
                            topBar
                            Spacer()
                            callControls
                        }
                    }
                } else {
                    preCallView
                }
            }
            .navigationTitle("Calls")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if passcode.isEmpty { generatePasscode() }
                manager.setup()
            }
            .alert("Connect", isPresented: $showConnectDialog) {
                Button("Join Now") { manager.join() }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var videoOffPlaceholder: some View {
        VStack(spacing: 20) {
            Image(systemName: "video.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("Video is Off")
                .foregroundColor(.white)
        }
    }
    
    private var topBar: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Passcode").font(.caption).foregroundColor(.white.opacity(0.7))
                Text(passcode).font(.headline).foregroundColor(.white)
            }
            .padding(10)
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            
            Spacer()
            
            HStack {
                Circle().fill(.red).frame(width: 8, height: 8)
                Text("LIVE").font(.caption).bold().foregroundColor(.white)
            }
            .padding(8)
            .background(Color.black.opacity(0.5))
            .cornerRadius(20)
        }
        .padding()
    }
    
    private var callControls: some View {
        HStack(spacing: 30) {
            controlButton(icon: manager.isMuted ? "mic.slash.fill" : "mic.fill", color: manager.isMuted ? .red : .white.opacity(0.2)) {
                manager.toggleMute()
            }
            
            controlButton(icon: manager.isVideoEnabled ? "video.fill" : "video.slash.fill", color: manager.isVideoEnabled ? .white.opacity(0.2) : .red) {
                manager.toggleVideo()
            }
            
            controlButton(icon: "camera.rotate.fill", color: .white.opacity(0.2)) {
                isFrontCamera.toggle()
            }
            
            controlButton(icon: "phone.down.fill", color: .red) {
                manager.leave()
            }
        }
        .padding(.bottom, 40)
    }
    
    private func controlButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(color)
                .clipShape(Circle())
        }
    }
    
    private var preCallView: some View {
        VStack(spacing: 30) {
            Text(passcode)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Button("Connect to Call") {
                showConnectDialog = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private func generatePasscode() {
        passcode = String((0..<6).map { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! })
    }
}
