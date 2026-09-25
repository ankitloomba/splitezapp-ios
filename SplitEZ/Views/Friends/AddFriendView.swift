import SwiftUI
import CoreNFC
import CoreImage.CIFilterBuiltins

// MARK: - Tab enum

private enum AddFriendTab: String, CaseIterable {
    case email = "Email"
    case scanQR = "Scan QR"
    case myQR = "My QR"
    case nfc = "Tap"
    case code = "Enter Code"

    var icon: String {
        switch self {
        case .email: return "envelope.fill"
        case .scanQR: return "qrcode.viewfinder"
        case .myQR: return "qrcode"
        case .nfc: return "wave.3.right"
        case .code: return "key.horizontal.fill"
        }
    }
}

// MARK: - Main sheet

struct AddFriendView: View {
    @Binding var isPresented: Bool
    var onFriendAdded: () -> Void = {}
    var groups: [ExpenseGroup] = []

    @State private var activeTab: AddFriendTab = .email

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            Text("Add Friend")
                .font(.title3.weight(.bold))
                .padding(.vertical, 14)

            // Tab picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(AddFriendTab.allCases, id: \.self) { tab in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { activeTab = tab }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 16))
                                Text(tab.rawValue)
                                    .font(.caption.weight(.medium))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(activeTab == tab ? SplitEZTheme.primary : Color(.systemGray6))
                            )
                            .foregroundColor(activeTab == tab ? .white : SplitEZTheme.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            Divider().padding(.top, 12)

            // Content
            ScrollView {
                Group {
                    switch activeTab {
                    case .email:
                        EmailTabView(isPresented: $isPresented, onFriendAdded: onFriendAdded, groups: groups)
                    case .scanQR:
                        ScanQRTabView(isPresented: $isPresented, onFriendAdded: onFriendAdded)
                    case .myQR:
                        MyQRTabView()
                    case .nfc:
                        NFCTabView()
                    case .code:
                        EnterCodeTabView(isPresented: $isPresented, onFriendAdded: onFriendAdded, groups: groups)
                    }
                }
                .padding(20)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Email tab

private struct EmailTabView: View {
    @Binding var isPresented: Bool
    var onFriendAdded: () -> Void
    var groups: [ExpenseGroup]

    @State private var email = ""
    @State private var error: String?
    @State private var selectedGroupIds = Set<String>()
    @State private var showGroupPicker = false

    var body: some View {
        VStack(spacing: 16) {
            TextField("friend@example.com", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.systemGray6))
                )

            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(SplitEZTheme.negative)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Add to group toggle
            Button {
                withAnimation { showGroupPicker.toggle() }
            } label: {
                HStack {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 14))
                        .foregroundColor(selectedGroupIds.isEmpty ? SplitEZTheme.textSecondary : SplitEZTheme.primary)
                    Text(selectedGroupIds.isEmpty ? "Also add to a group (optional)" :
                         "\(selectedGroupIds.count) group\(selectedGroupIds.count == 1 ? "" : "s") selected")
                        .font(.subheadline)
                        .foregroundColor(selectedGroupIds.isEmpty ? SplitEZTheme.textSecondary : SplitEZTheme.primary)
                    Spacer()
                    Image(systemName: showGroupPicker ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(SplitEZTheme.textTertiary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(selectedGroupIds.isEmpty ? Color(.systemGray4) : SplitEZTheme.primary, lineWidth: 1)
                )
            }

            if showGroupPicker {
                VStack(spacing: 0) {
                    ForEach(groups, id: \.id) { group in
                        let isSelected = selectedGroupIds.contains(group.id)
                        Button {
                            if isSelected { selectedGroupIds.remove(group.id) }
                            else { selectedGroupIds.insert(group.id) }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "person.3.fill")
                                    .foregroundColor(SplitEZTheme.primary)
                                Text(group.name)
                                    .font(.subheadline)
                                    .foregroundColor(SplitEZTheme.textPrimary)
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(SplitEZTheme.primary)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(isSelected ? SplitEZTheme.primary.opacity(0.06) : Color.clear)
                        }
                        Divider().padding(.leading, 44)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.systemGray6))
                )
            }

            Button {
                if email.contains("@") {
                    onFriendAdded()
                    isPresented = false
                } else {
                    error = "Please enter a valid email address."
                }
            } label: {
                Text("Send friend request")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(email.isEmpty ? SplitEZTheme.primary.opacity(0.4) : SplitEZTheme.primary)
                    )
            }
            .disabled(email.isEmpty)

            dividerOr

            InviteCodeCard()
        }
    }
}

// MARK: - Scan QR tab

private struct ScanQRTabView: View {
    @Binding var isPresented: Bool
    var onFriendAdded: () -> Void
    @State private var scannedCode: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Scan a friend's QR code")
                .font(.headline)
            Text("Ask your friend to show their QR code from the \"My QR\" tab")
                .font(.subheadline)
                .foregroundColor(SplitEZTheme.textSecondary)
                .multilineTextAlignment(.center)

            if let code = scannedCode {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    Text("Code scanned!")
                        .font(.headline)
                    Text(code)
                        .font(.caption)
                        .foregroundColor(SplitEZTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.green.opacity(0.08))
                )

                Button {
                    onFriendAdded()
                    isPresented = false
                } label: {
                    Text("Add Friend")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 24).fill(SplitEZTheme.primary))
                }

                Button { scannedCode = nil } label: {
                    Text("Scan again")
                        .foregroundColor(SplitEZTheme.primary)
                }
            } else {
                // Viewfinder frame
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.systemGray6))
                        .frame(width: 220, height: 220)

                    Image(systemName: "camera.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color(.systemGray3))

                    ScannerCorners()
                }

                Button {
                    // iOS QR scanning requires AVFoundation camera sheet — present via UIKit
                    QRScannerCoordinator.shared.scan { result in
                        scannedCode = result
                    }
                } label: {
                    Label("Open Scanner", systemImage: "qrcode.viewfinder")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 24).fill(SplitEZTheme.primary))
                }
            }
        }
    }
}

// MARK: - My QR tab

private struct MyQRTabView: View {
    private let inviteCode = InviteCodeHelper.code
    private var qrImage: UIImage? { generateQR("splitez://add?code=\(inviteCode)") }

    var body: some View {
        VStack(spacing: 20) {
            Text("Your QR Code")
                .font(.headline)
            Text("Let friends scan this to add you instantly")
                .font(.subheadline)
                .foregroundColor(SplitEZTheme.textSecondary)
                .multilineTextAlignment(.center)

            // QR card
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                    .frame(width: 220, height: 220)

                if let img = qrImage {
                    Image(uiImage: img)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 188, height: 188)
                } else {
                    ProgressView()
                }
            }

            // Invite code pill
            Text(inviteCode)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(SplitEZTheme.primary)
                .kerning(4)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(SplitEZTheme.primary.opacity(0.08))
                )

            HStack(spacing: 12) {
                Button {
                    UIPasteboard.general.string = inviteCode
                } label: {
                    Label("Copy", systemImage: "doc.on.doc.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(SplitEZTheme.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(SplitEZTheme.primary, lineWidth: 1.5))
                }

                ShareLink(item: "Join me on SplitEZ! Use invite code: \(inviteCode)\nOr scan my QR code in the app.") {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 24).fill(SplitEZTheme.primary))
                }
            }
        }
    }

    private func generateQR(_ content: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(content.utf8)
        filter.correctionLevel = "M"
        guard let ciImage = filter.outputImage else { return nil }
        let scale: CGFloat = 10
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let scaledImage = ciImage.transformed(by: transform)
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - NFC tab

private struct NFCTabView: View {
    @State private var isListening = false
    private var nfcAvailable: Bool { NFCNDEFReaderSession.readingAvailable }

    var body: some View {
        VStack(spacing: 20) {
            Text("Tap to Connect")
                .font(.headline)
            Text("Hold your iPhones together to add each other instantly")
                .font(.subheadline)
                .foregroundColor(SplitEZTheme.textSecondary)
                .multilineTextAlignment(.center)

            // NFC circle
            ZStack {
                Circle()
                    .fill(isListening ? SplitEZTheme.primary.opacity(0.12) : Color(.systemGray6))
                    .frame(width: 160, height: 160)
                    .overlay(
                        Circle()
                            .strokeBorder(isListening ? SplitEZTheme.primary.opacity(0.4) : Color(.systemGray4), lineWidth: 2)
                    )

                VStack(spacing: 8) {
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 48))
                        .foregroundColor(isListening ? SplitEZTheme.primary : Color(.systemGray3))
                    Text(isListening ? "Listening…" : "Ready")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(isListening ? SplitEZTheme.primary : SplitEZTheme.textSecondary)
                }
            }

            if !nfcAvailable {
                Text("NFC is not available on this device. Use QR code or invite code instead.")
                    .font(.subheadline)
                    .foregroundColor(SplitEZTheme.textSecondary)
                    .multilineTextAlignment(.center)
            } else if !isListening {
                Button {
                    isListening = true
                    NFCHelper.shared.startSession(inviteCode: InviteCodeHelper.code) {
                        isListening = false
                    }
                } label: {
                    Label("Start Tap Mode", systemImage: "wave.3.right")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 24).fill(SplitEZTheme.primary))
                }
            } else {
                Text("Hold iPhones together now")
                    .font(.headline)
                    .foregroundColor(SplitEZTheme.primary)
                Text("Keep the tops of the phones close until connected")
                    .font(.subheadline)
                    .foregroundColor(SplitEZTheme.textSecondary)
                    .multilineTextAlignment(.center)

                Button {
                    isListening = false
                    NFCHelper.shared.stopSession()
                } label: {
                    Text("Cancel")
                        .foregroundColor(SplitEZTheme.textSecondary)
                }
            }
        }
    }
}

// MARK: - Enter Code tab

private struct EnterCodeTabView: View {
    @Binding var isPresented: Bool
    var onFriendAdded: () -> Void
    var groups: [ExpenseGroup]

    @State private var code = ""
    @State private var error: String?
    @State private var selectedGroupIds = Set<String>()
    @State private var showGroupPicker = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Enter friend's invite code")
                .font(.headline)
            Text("Ask your friend for their 6-character code from the \"My QR\" tab")
                .font(.subheadline)
                .foregroundColor(SplitEZTheme.textSecondary)
                .multilineTextAlignment(.center)

            TextField("ABC123", text: Binding(
                get: { code },
                set: { code = String($0.uppercased().prefix(6)) }
            ))
            .font(.system(size: 32, weight: .bold, design: .monospaced))
            .kerning(6)
            .multilineTextAlignment(.center)
            .autocapitalization(.allCharacters)
            .autocorrectionDisabled()
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(SplitEZTheme.primary.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(SplitEZTheme.primary.opacity(0.2), lineWidth: 1)
                    )
            )
            .foregroundColor(SplitEZTheme.primary)

            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(SplitEZTheme.negative)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Add to group toggle
            Button {
                withAnimation { showGroupPicker.toggle() }
            } label: {
                HStack {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 14))
                        .foregroundColor(selectedGroupIds.isEmpty ? SplitEZTheme.textSecondary : SplitEZTheme.primary)
                    Text(selectedGroupIds.isEmpty ? "Also add to a group (optional)" :
                         "\(selectedGroupIds.count) group\(selectedGroupIds.count == 1 ? "" : "s") selected")
                        .font(.subheadline)
                        .foregroundColor(selectedGroupIds.isEmpty ? SplitEZTheme.textSecondary : SplitEZTheme.primary)
                    Spacer()
                    Image(systemName: showGroupPicker ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(SplitEZTheme.textTertiary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(selectedGroupIds.isEmpty ? Color(.systemGray4) : SplitEZTheme.primary, lineWidth: 1)
                )
            }

            if showGroupPicker {
                VStack(spacing: 0) {
                    ForEach(groups, id: \.id) { group in
                        let isSelected = selectedGroupIds.contains(group.id)
                        Button {
                            if isSelected { selectedGroupIds.remove(group.id) }
                            else { selectedGroupIds.insert(group.id) }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "person.3.fill")
                                    .foregroundColor(SplitEZTheme.primary)
                                Text(group.name)
                                    .font(.subheadline)
                                    .foregroundColor(SplitEZTheme.textPrimary)
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(SplitEZTheme.primary)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(isSelected ? SplitEZTheme.primary.opacity(0.06) : Color.clear)
                        }
                        Divider().padding(.leading, 44)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.systemGray6))
                )
            }

            Button {
                if code.count == 6 {
                    onFriendAdded()
                    isPresented = false
                } else {
                    error = "Code must be 6 characters."
                }
            } label: {
                Text("Add Friend")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(code.count == 6 ? SplitEZTheme.primary : SplitEZTheme.primary.opacity(0.4))
                    )
            }
            .disabled(code.count != 6)
        }
    }
}

// MARK: - Shared: Invite Code Card

private struct InviteCodeCard: View {
    private let inviteCode = InviteCodeHelper.code

    var body: some View {
        VStack(spacing: 12) {
            Text("Your invite code")
                .font(.subheadline.weight(.medium))
                .foregroundColor(SplitEZTheme.textSecondary)

            Text(inviteCode)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(SplitEZTheme.primary)
                .kerning(4)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(SplitEZTheme.primary.opacity(0.08))
                )

            ShareLink(item: "Join me on SplitEZ! Use invite code: \(inviteCode)\n\nDownload SplitEZ and enter this code to connect.") {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share invite link")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(SplitEZTheme.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(SplitEZTheme.primary, lineWidth: 1.5))
            }
        }
    }
}

// MARK: - Scanner corners decoration

private struct ScannerCorners: View {
    var body: some View {
        Canvas { ctx, size in
            let cs: CGFloat = 28
            let sw: CGFloat = 3
            let color = GraphicsContext.Shading.color(SplitEZTheme.primary)
            func stroke(_ path: Path) { ctx.stroke(path, with: color, lineWidth: sw) }

            // TL
            var tl = Path(); tl.move(to: CGPoint(x: 0, y: cs)); tl.addLine(to: .zero); tl.addLine(to: CGPoint(x: cs, y: 0))
            // TR
            var tr = Path(); tr.move(to: CGPoint(x: size.width - cs, y: 0)); tr.addLine(to: CGPoint(x: size.width, y: 0)); tr.addLine(to: CGPoint(x: size.width, y: cs))
            // BL
            var bl = Path(); bl.move(to: CGPoint(x: 0, y: size.height - cs)); bl.addLine(to: CGPoint(x: 0, y: size.height)); bl.addLine(to: CGPoint(x: cs, y: size.height))
            // BR
            var br = Path(); br.move(to: CGPoint(x: size.width - cs, y: size.height)); br.addLine(to: CGPoint(x: size.width, y: size.height)); br.addLine(to: CGPoint(x: size.width, y: size.height - cs))

            [tl, tr, bl, br].forEach { stroke($0) }
        }
        .frame(width: 220, height: 220)
    }
}

// MARK: - Helpers

private var dividerOr: some View {
    HStack {
        Rectangle().fill(Color(.systemGray4)).frame(height: 1)
        Text("or share invite").font(.caption).foregroundColor(SplitEZTheme.textTertiary).fixedSize()
        Rectangle().fill(Color(.systemGray4)).frame(height: 1)
    }
}

@MainActor
enum InviteCodeHelper {
    static var code: String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        let id = AuthService.shared.currentUser?.id ?? "default"
        var s = abs((id + "invite").hashValue)
        var result = ""
        for _ in 0..<6 {
            result.append(chars[chars.index(chars.startIndex, offsetBy: s % chars.count)])
            s /= chars.count
        }
        return result
    }
}

// MARK: - NFC helper (stub; full impl requires NFCNDEFReaderSession delegate)

final class NFCHelper: NSObject {
    static let shared = NFCHelper()
    private var session: NFCNDEFReaderSession?
    private var onComplete: (() -> Void)?

    func startSession(inviteCode: String, onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        guard NFCNDEFReaderSession.readingAvailable else { onComplete(); return }
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = "Hold your iPhone near another iPhone running SplitEZ."
        session?.begin()
    }

    func stopSession() {
        session?.invalidate()
        session = nil
        onComplete?()
        onComplete = nil
    }
}

extension NFCHelper: NFCNDEFReaderSessionDelegate {
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async { self.onComplete?(); self.onComplete = nil }
    }
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        DispatchQueue.main.async { self.onComplete?(); self.onComplete = nil }
    }
}

// MARK: - QR Scanner coordinator (stub; presents AVFoundation camera via UIKit)

final class QRScannerCoordinator: NSObject {
    static let shared = QRScannerCoordinator()
    private var completion: ((String) -> Void)?

    func scan(completion: @escaping (String) -> Void) {
        self.completion = completion
        // In a real implementation, present a UIViewController with AVCaptureSession.
        // For now this is a stub that the camera-usage NSUsageDescription covers.
    }
}
