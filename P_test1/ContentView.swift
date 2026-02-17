//
//  ContentView.swift
//  P_test1
//
//  Created by Pavan Yadav on 10/12/25.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import AVFoundation

struct ContentView: View {
    @State private var ports: [PortConfig] = PortConfig.samples
    @State private var selectedPort: PortConfig = PortConfig.samples.first!
    @State private var copied = false
    @State private var isSpeaking = false
    @State private var marqueePhase: CGFloat = -1.0

    @State private var showScanner = false
    @State private var scannedText: String? = nil
    @State private var showAddPortSheet = false
    @State private var newPortTitle: String = ""
    @State private var showSidebar = false
    @State private var sortMode: SortMode = .recentlyAdded

    @State private var favorites: Set<PortConfig.ID> = []
    @State private var lastUsedMap: [PortConfig.ID: Date] = [:]
    @State private var addedAtMap: [PortConfig.ID: Date] = [:]
    
    @State private var showPermissionAlert = false
    @State private var permissionAlertMessage = ""
    @State private var isDarkMode = false
    @State private var searchText = ""

    private let context = CIContext()
    private let qrFilter = CIFilter.qrCodeGenerator()
    private let speaker = AVSpeechSynthesizer()
    private let speechDelegate = SpeechDelegate()

    final class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
        var onStart: (() -> Void)?
        var onFinish: (() -> Void)?

        func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
            onStart?()
        }
        func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
            onFinish?()
        }
        func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
            onFinish?()
        }
    }

    enum SortMode: String, CaseIterable, Identifiable {
        case recentlyUsed = "Recently Used"
        case recentlyAdded = "Recently Added"
        var id: String { rawValue }
    }

    private func markUsed(_ port: PortConfig) {
        lastUsedMap[port.id] = Date()
    }

    private func sortedPorts() -> [PortConfig] {
        switch sortMode {
        case .recentlyUsed:
            return ports.sorted { (a, b) in
                (lastUsedMap[a.id] ?? .distantPast) > (lastUsedMap[b.id] ?? .distantPast)
            }
        case .recentlyAdded:
            return ports.sorted { (a, b) in
                (addedAtMap[a.id] ?? .distantPast) > (addedAtMap[b.id] ?? .distantPast)
            }
        }
    }

    private func redirectToBusinessnext() {
        guard let encodedData = selectedPort.jsonString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        
        let deepLinkURL = "businessnextparent://port-data?data=\(encodedData)"
        
        #if canImport(UIKit)
        if let url = URL(string: deepLinkURL) {
            UIApplication.shared.open(url) { success in
                if !success {
                    // Fallback: Handle case where Businessnext app is not installed
                    // You could show an alert or redirect to App Store
                    print("Businessnext app not installed or deep link failed")
                }
            }
        }
        #endif
    }

    private func containsPort(withJSON json: String) -> Bool {
        ports.contains { $0.jsonString == json }
    }

    private var selectedTitle: String {
        // Derive title from selectedPort.mainAppUrl (e.g., last path component like "g8tab")
        let urlString = selectedPort.mainAppUrl
        if let url = URL(string: urlString) {
            let components = url.pathComponents.filter { $0 != "/" }
            if let last = components.last, !last.isEmpty {
                return last
            }
        }
        // Fallback to name if parsing fails
        return selectedPort.name
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .leading) {
                // Sidebar drawer
                if showSidebar {
                    SidebarView(
                        ports: $ports,
                        selectedPort: $selectedPort,
                        sortMode: $sortMode,
                        favorites: $favorites,
                        isDarkMode: $isDarkMode,
                        searchText: $searchText,
                        onSelect: { port in
                            selectedPort = port
                            withAnimation { showSidebar = false }
                        }
                    )
                    .frame(width: 280)
                    .transition(.move(edge: .leading))
                    .zIndex(1)
                }

                // Main content
                VStack(spacing: 16) {
                    if isSpeaking {
                        EmojiMarquee(phase: $marqueePhase)
                            .frame(height: 32)
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Top: Port picker (drop-down)
                    Picker(selectedTitle, selection: $selectedPort) {
                        ForEach(sortedPorts()) { port in
                            Text(port.name)
                                .tag(port)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedPort) { newValue in
                        #if canImport(UIKit)
                        let deviceName = UIDevice.current.name
                        #else
                        let deviceName = "there"
                        #endif
                        let utterance = AVSpeechUtterance(string: "You have selected \(newValue.name)")

                        if let preferredVoice = AVSpeechSynthesisVoice(language: "en-US") {
                            utterance.voice = preferredVoice
                        } else {
                            utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.identifier)
                        }

                        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.7
                        utterance.pitchMultiplier = 1.05
                        utterance.volume = 1.0
                        utterance.prefersAssistiveTechnologySettings = true
                        utterance.preUtteranceDelay = 0.05
                        utterance.postUtteranceDelay = 0.05

                        speaker.delegate = speechDelegate
                        speechDelegate.onStart = {
                            withAnimation(.easeInOut) {
                                isSpeaking = true
                                marqueePhase = -1.0
                            }
                        }
                        speechDelegate.onFinish = {
                            withAnimation(.easeInOut) {
                                isSpeaking = false
                            }
                        }

                        speaker.stopSpeaking(at: .immediate)
                        speaker.speak(utterance)
                        markUsed(newValue)
                    }
                    .padding(.horizontal)

                    // Middle: QR code generated from selected port JSON
                    QRCodeView(text: selectedPort.jsonString)
                        .frame(width: 220, height: 220)
                        .padding()
                        .background(selectedPort.stableColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Bottom: Selected data with copy button on the top-right corner
                    ZStack(alignment: .topTrailing) {
                        ScrollView {
                            Text(selectedPort.jsonString)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .background(selectedPort.stableColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        Button {
                            #if canImport(UIKit)
                            UIPasteboard.general.string = selectedPort.jsonString
                            #endif
                            withAnimation { copied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation { copied = false }
                            }
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                                .labelStyle(.iconOnly)
                                .padding(10)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .padding(8)
                        .accessibilityLabel("Copy port data")
                    }
                    .padding(.horizontal)

                    // Redirect to Businessnext button
                    Button {
                        redirectToBusinessnext()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up.right.square")
                            Text("Redirect to Businessnext")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 0)
                }
                .overlay(alignment: .topLeading) {
                    // Scrim to close sidebar on tap
                    if showSidebar {
                        Color.black.opacity(0.001)
                            .contentShape(Rectangle())
                            .onTapGesture { withAnimation { showSidebar = false } }
                    }
                }
            }

            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation { showSidebar.toggle() }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                    .accessibilityLabel("Toggle sidebar")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let status = AVCaptureDevice.authorizationStatus(for: .video)
                        switch status {
                        case .authorized:
                            showScanner = true
                        case .notDetermined:
                            AVCaptureDevice.requestAccess(for: .video) { granted in
                                DispatchQueue.main.async {
                                    if granted {
                                        showScanner = true
                                    } else {
                                        permissionAlertMessage = "Camera access is required to scan QR codes. You can enable it in Settings."
                                        showPermissionAlert = true
                                    }
                                }
                            }
                        case .denied, .restricted:
                            permissionAlertMessage = "Camera access is required to scan QR codes. You can enable it in Settings."
                            showPermissionAlert = true
                        @unknown default:
                            permissionAlertMessage = "Camera access is required to scan QR codes."
                            showPermissionAlert = true
                        }
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                    }
                    .accessibilityLabel("Scan QR")
                }
            }
            .sheet(isPresented: $showScanner) {
                QRScannerView { result in
                    showScanner = false
                    switch result {
                    case .success(let code):
                        scannedText = code
                        if let existing = ports.first(where: { $0.jsonString == code }) {
                            selectedPort = existing
                        } else {
                            // Show the scanned data; adding requires PortConfig initializer info
                            newPortTitle = ""
                            showAddPortSheet = true
                        }
                    case .failure:
                        break
                    }
                }
            }
            .sheet(isPresented: $showAddPortSheet) {
                NavigationStack {
                    Form {
                        Section("Scanned QR") {
                            if let scannedText {
                                ScrollView { Text(scannedText).font(.system(.footnote, design: .monospaced)) }
                                    .frame(maxHeight: 240)
                            } else {
                                Text("No data")
                            }
                        }
                        Section("Add to Ports") {
                            Text("Adding new ports requires the app's PortConfig initializer. Share the PortConfig model and I will wire this up.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .navigationTitle("Scanned Result")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showAddPortSheet = false }
                        }
                    }
                }
            }
            .alert("Camera Access Needed", isPresented: $showPermissionAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Open Settings") {
                    #if canImport(UIKit)
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                    #endif
                }
            } message: {
                Text(permissionAlertMessage)
            }
            .onAppear {
                if addedAtMap.isEmpty {
                    let now = Date()
                    for (i, p) in ports.enumerated() {
                        addedAtMap[p.id] = now.addingTimeInterval(TimeInterval(-i))
                    }
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}

// MARK: - QR Code View
struct QRCodeView: View {
    let text: String
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        GeometryReader { proxy in
            if let image = generateQRCode(from: text, size: proxy.size) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: proxy.size.width, height: proxy.size.height)
            } else {
                Color.gray.opacity(0.2)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func generateQRCode(from string: String, size: CGSize) -> UIImage? {
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.correctionLevel = "M"
        guard let outputImage = filter.outputImage else { return nil }
        let scaleX = size.width / outputImage.extent.size.width
        let scaleY = size.height / outputImage.extent.size.height
        let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        let cgImage = CIContext().createCGImage(transformed, from: transformed.extent)
        return cgImage.map { UIImage(cgImage: $0) }
    }
}

// MARK: - Emoji Marquee
struct EmojiMarquee: View {
    @Binding var phase: CGFloat
    private let emojis = ["🎵", "🎶", "🕺", "💃", "🎉", "✨", "🎧", "🎼", "🎺", "🥳"]

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            HStack(spacing: 12) {
                ForEach(0..<emojis.count, id: \.self) { idx in
                    Text(emojis[idx])
                        .font(.system(size: 22))
                        .rotationEffect(.degrees(Double(Int(phase * 100 + CGFloat(idx) * 10) % 20 - 10)))
                        .shadow(color: randomColor(idx).opacity(0.6), radius: 4, x: 0, y: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .offset(x: phase * width)
            .onAppear { animate(width: width) }
            .onChange(of: phase) { _ in }
        }
    }

    private func animate(width: CGFloat) {
        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
            phase = 1.0
        }
    }

    private func randomColor(_ seed: Int) -> Color {
        let colors: [Color] = [.red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .pink]
        return colors[seed % colors.count]
    }
}

// MARK: - QR Scanner View
struct QRScannerView: UIViewControllerRepresentable {
    enum ScanError: Error { case notFound, permissionDenied }
    let onComplete: (Result<String, ScanError>) -> Void

    func makeUIViewController(context: Context) -> ScannerController {
        let vc = ScannerController()
        vc.onComplete = onComplete
        return vc
    }
    func updateUIViewController(_ uiViewController: ScannerController, context: Context) {}

    final class ScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
        var onComplete: ((Result<String, ScanError>) -> Void)?
        private let session = AVCaptureSession()
        private let preview = AVCaptureVideoPreviewLayer()

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .black
            setupCamera()
        }

        private func setupCamera() {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    DispatchQueue.main.async { granted ? self.configureSession() : self.onComplete?(.failure(.permissionDenied)) }
                }
            case .authorized:
                configureSession()
            case .denied, .restricted:
                onComplete?(.failure(.permissionDenied))
            @unknown default:
                onComplete?(.failure(.permissionDenied))
            }
        }

        private func configureSession() {
            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                onComplete?(.failure(.notFound)); return
            }
            session.beginConfiguration()
            if session.canAddInput(input) { session.addInput(input) }
            let output = AVCaptureMetadataOutput()
            if session.canAddOutput(output) { session.addOutput(output) }
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            output.metadataObjectTypes = [.qr]
            session.commitConfiguration()

            preview.session = session
            preview.videoGravity = .resizeAspectFill
            preview.frame = view.layer.bounds
            view.layer.addSublayer(preview)
            session.startRunning()
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  obj.type == .qr,
                  let string = obj.stringValue else { return }
            session.stopRunning()
            onComplete?(.success(string))
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            preview.frame = view.bounds
        }
    }
}

// MARK: - Sidebar View
struct SidebarView: View {
    @Binding var ports: [PortConfig]
    @Binding var selectedPort: PortConfig
    @Binding var sortMode: ContentView.SortMode
    @Binding var favorites: Set<PortConfig.ID>
    @Binding var isDarkMode: Bool
    @Binding var searchText: String
    var onSelect: (PortConfig) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Menu {
                    Button("Dark") {
                        isDarkMode = true
                    }
                    Button("Light") {
                        isDarkMode = false
                    }
                    Button("System") {
                        isDarkMode.toggle()
                    }
                } label: {
                    Label("Theme", systemImage: "paintbrush")
                }
            }
            .padding()
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search ports...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            List {
                // Filter ports based on search text
                let filteredPorts = ports.filter { port in
                    searchText.isEmpty || port.name.localizedCaseInsensitiveContains(searchText)
                }
                
                // Favorites Section
                let favoritePorts = filteredPorts.filter { favorites.contains($0.id) }
                if !favoritePorts.isEmpty {
                    Section("Favorites") {
                        ForEach(favoritePorts) { port in
                            portButton(port: port)
                        }
                    }
                }
                
                // Others Section
                let otherPorts = filteredPorts.filter { !favorites.contains($0.id) }
                Section(favoritePorts.isEmpty ? "Ports" : "Others") {
                    ForEach(otherPorts) { port in
                        portButton(port: port)
                    }
                }
            }
        }
        .background(.ultraThinMaterial)
    }
    
    private func portButton(port: PortConfig) -> some View {
        Button {
            onSelect(port)
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(port.name)
                    Text(port.mainAppUrl).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    if favorites.contains(port.id) { favorites.remove(port.id) } else { favorites.insert(port.id) }
                } label: {
                    Image(systemName: favorites.contains(port.id) ? "star.fill" : "star")
                }
            }
            .buttonStyle(.borderless)
        }
    }
}
    
    #Preview {
        ContentView()
    }


