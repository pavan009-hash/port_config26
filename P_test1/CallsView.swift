import SwiftUI
import Combine
import AVFoundation

final class AgoraCallManager: ObservableObject {
    // MARK: - Public published state
    @Published var isJoined = false
    @Published var isMuted = false
    @Published var isVideoEnabled = true
    @Published var remoteUserJoined = false
    @Published var isInCall = false

    // MARK: - Config (demo mode)
    var appId: String = "DEMO_MODE"
    var channelName: String = ""
    var token: String? = nil
    var uid: UInt = 0

    // MARK: - Setup
    func setup() {
        // Demo mode - request permissions for future use
        requestPermissionsIfNeeded()
    }

    func join(channel: String) {
        self.channelName = channel
        requestPermissionsIfNeeded()
        
        // Always use demo mode
        DispatchQueue.main.async {
            self.isJoined = true
            self.isInCall = true
        }
    }

    func leave() {
        DispatchQueue.main.async {
            self.isJoined = false
            self.remoteUserJoined = false
            self.isMuted = false
            self.isVideoEnabled = true
            self.isInCall = false
        }
    }

    func toggleMute() {
        isMuted.toggle()
    }

    func toggleVideo() {
        isVideoEnabled.toggle()
    }

    func switchCamera() {
        // Demo mode - camera switching handled in UI
    }

    private func requestPermissionsIfNeeded() {
        #if canImport(UIKit)
        AVCaptureDevice.requestAccess(for: .video) { granted in
            print("Camera permission granted: \(granted)")
        }
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            print("Microphone permission granted: \(granted)")
        }
        #endif
    }
}

struct CallsView: View {
    @StateObject private var manager = AgoraCallManager()
    @State private var remoteUid: UInt? = 1
    @State private var passcode: String = ""
    @State private var connectCode: String = ""
    @State private var showConnectDialog = false
    @State private var isFullscreen = false
    @State private var showPasscode = true
    @State private var isFrontCamera = true
    @State private var cameraOffset: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if manager.isInCall {
                    // In-call UI
                    ZStack {
                        // Video background
                        if manager.isVideoEnabled {
                            // Simulated camera view
                            ZStack {
                                // Camera feed simulation - more visible
                                RoundedRectangle(cornerRadius: 0)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                isFrontCamera ? Color.black : Color.gray.opacity(0.6),
                                                isFrontCamera ? Color.gray.opacity(0.4) : Color.black.opacity(0.8),
                                                isFrontCamera ? Color.black.opacity(0.9) : Color.gray.opacity(0.3)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .ignoresSafeArea()
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            isFrontCamera.toggle()
                                        }
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                        impactFeedback.impactOccurred()
                                    }
                                
                                // Camera overlay elements
                                VStack {
                                    HStack {
                                        Spacer()
                                        HStack {
                                            Circle()
                                                .fill(Color.red)
                                                .frame(width: 8, height: 8)
                                            Text("LIVE")
                                                .foregroundColor(.white)
                                                .font(.caption)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.black.opacity(0.5))
                                        .cornerRadius(4)
                                        .padding()
                                    }
                                    
                                    Spacer()
                                    
                                    HStack {
                                        if manager.isMuted {
                                            HStack {
                                                Image(systemName: "mic.slash.fill")
                                                    .foregroundColor(.red)
                                                Text("Muted")
                                                    .foregroundColor(.red)
                                            }
                                            .padding()
                                            .background(Color.black.opacity(0.7))
                                            .cornerRadius(8)
                                        }
                                        Spacer()
                                        Text(isFrontCamera ? "Front Camera" : "Back Camera")
                                            .foregroundColor(.white.opacity(0.7))
                                            .font(.caption)
                                            .padding()
                                            .background(Color.black.opacity(0.5))
                                            .cornerRadius(8)
                                    }
                                    .padding()
                                }
                                
                                // Center content
                                VStack {
                                    Spacer()
                                    Text(isFrontCamera ? "Front Camera" : "Back Camera")
                                        .foregroundColor(.white.opacity(0.8))
                                        .font(.title2)
                                    Text("Tap to switch camera")
                                        .foregroundColor(.white.opacity(0.6))
                                        .font(.caption)
                                        .padding(.top, 4)
                                    Spacer()
                                }
                            }
                        } else {
                            // Video off screen
                            ZStack {
                                Color.black
                                VStack {
                                    Image(systemName: "video.slash.fill")
                                        .font(.system(size: 80))
                                        .foregroundColor(.red.opacity(0.7))
                                    Text("Video Off")
                                        .foregroundColor(.white.opacity(0.7))
                                        .font(.title)
                                        .padding(.top)
                                }
                            }
                        }
                        
                        // Top controls
                        VStack {
                            HStack {
                                if showPasscode {
                                    VStack {
                                        Text("Your Passcode")
                                            .foregroundColor(.white.opacity(0.8))
                                            .font(.caption)
                                        Text(passcode)
                                            .foregroundColor(.white)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.black.opacity(0.5))
                                            .cornerRadius(8)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation {
                                        showPasscode.toggle()
                                    }
                                }) {
                                    Image(systemName: showPasscode ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.black.opacity(0.5))
                                        .clipShape(Circle())
                                }
                            }
                            .padding()
                            
                            Spacer()
                            
                            // Bottom controls
                            HStack(spacing: 30) {
                                Button(action: { 
                                    manager.isMuted.toggle()
                                }) {
                                    Image(systemName: manager.isMuted ? "mic.slash.fill" : "mic.fill")
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(manager.isMuted ? Color.red : Color.black.opacity(0.5))
                                        .clipShape(Circle())
                                        .frame(width: 50, height: 50)
                                }
                                .overlay(
                                    Text(manager.isMuted ? "Unmute" : "Mute")
                                        .foregroundColor(.white.opacity(0.6))
                                        .font(.caption2)
                                        .offset(y: 35)
                                )
                                
                                Button(action: { 
                                    manager.isVideoEnabled.toggle()
                                }) {
                                    Image(systemName: manager.isVideoEnabled ? "video.fill" : "video.slash.fill")
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(manager.isVideoEnabled ? Color.black.opacity(0.5) : Color.red)
                                        .clipShape(Circle())
                                        .frame(width: 50, height: 50)
                                }
                                .overlay(
                                    Text(manager.isVideoEnabled ? "Video Off" : "Video On")
                                        .foregroundColor(.white.opacity(0.6))
                                        .font(.caption2)
                                        .offset(y: 35)
                                )
                                
                                Button(action: { 
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isFrontCamera.toggle()
                                    }
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                }) {
                                    Image(systemName: "camera.rotate.fill")
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.black.opacity(0.5))
                                        .clipShape(Circle())
                                        .frame(width: 50, height: 50)
                                }
                                .overlay(
                                    Text("Switch")
                                        .foregroundColor(.white.opacity(0.6))
                                        .font(.caption2)
                                        .offset(y: 35)
                                )
                                
                                Button(action: { 
                                    withAnimation {
                                        isFullscreen.toggle()
                                    }
                                }) {
                                    Image(systemName: isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(isFullscreen ? Color.blue.opacity(0.7) : Color.black.opacity(0.5))
                                        .clipShape(Circle())
                                        .frame(width: 50, height: 50)
                                }
                                .overlay(
                                    Text(isFullscreen ? "Exit" : "Full")
                                        .foregroundColor(.white.opacity(0.6))
                                        .font(.caption2)
                                        .offset(y: 35)
                                )
                                
                                Button(role: .destructive, action: { 
                                    manager.leave()
                                    isFullscreen = false
                                }) {
                                    Image(systemName: "phone.down.fill")
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.red)
                                        .clipShape(Circle())
                                        .frame(width: 60, height: 60)
                                }
                            }
                            .padding(.bottom, 30)
                        }
                    }
                } else {
                    // Pre-call UI
                    VStack(spacing: 30) {
                        Spacer()
                        
                        // Passcode display
                        VStack(spacing: 20) {
                            Text("Your Passcode")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.title2)
                            
                            Text(passcode)
                                .foregroundColor(.white)
                                .font(.system(size: 48, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(16)
                            
                            Text("Share this code with others to connect")
                                .foregroundColor(.white.opacity(0.6))
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Connect via code button
                        Button(action: {
                            showConnectDialog = true
                        }) {
                            HStack {
                                Image(systemName: "link")
                                Text("Connect via Code")
                            }
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Calls")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { 
                generatePasscode()
                manager.setup() 
            }
            .alert("Connect via Code", isPresented: $showConnectDialog) {
                TextField("Enter passcode", text: $connectCode)
                Button("Connect") {
                    if !connectCode.isEmpty {
                        // Always connect in demo mode for now
                        DispatchQueue.main.async {
                            manager.isInCall = true
                            manager.isJoined = true
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter the passcode shared by the other user")
            }
        }
    }
    
    private func generatePasscode() {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        passcode = String((0..<6).map { _ in characters.randomElement()! })
    }
}

#Preview {
    CallsView()
}
