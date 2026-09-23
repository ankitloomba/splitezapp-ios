import SwiftUI

struct SessionInfo: Identifiable {
    let id: String
    let deviceName: String
    let subtitle: String
    let isCurrentDevice: Bool
    let isActive: Bool
}

struct SecuritySettingsView: View {
    @State private var biometricEnabled = true
    @State private var appLockEnabled = false

    private let sessions = [
        SessionInfo(id: "s1", deviceName: "iPhone 15 Pro", subtitle: "Active now · this device", isCurrentDevice: true, isActive: true),
        SessionInfo(id: "s2", deviceName: "Chrome · Windows", subtitle: "Last active 2 days ago", isCurrentDevice: false, isActive: false)
    ]

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                SplitEZTheme.darkBg.frame(height: 120)
                Color(.systemBackground)
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Change password
                    securityRow(icon: "lock", title: "Change password", subtitle: "Last changed 3 months ago") {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(SplitEZTheme.textSecondary)
                    }
                    rowDivider

                    // Biometric login
                    securityRow(icon: "faceid", title: "Biometric login", subtitle: "Face ID / fingerprint") {
                        Toggle("", isOn: $biometricEnabled)
                            .labelsHidden()
                            .tint(SplitEZTheme.primary)
                    }
                    rowDivider

                    // App lock
                    securityRow(icon: "lock.app.dashed", title: "App lock", subtitle: "Require PIN on every open") {
                        Toggle("", isOn: $appLockEnabled)
                            .labelsHidden()
                            .tint(SplitEZTheme.primary)
                    }

                    // Sessions
                    sectionLabel("SESSIONS")

                    ForEach(sessions) { session in
                        sessionRow(session)
                        if session.id != sessions.last?.id {
                            rowDivider
                        }
                    }

                    // Log out all other devices
                    Button {
                    } label: {
                        Text("Log out all other devices")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(SplitEZTheme.negative)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(SplitEZTheme.negative, lineWidth: 1.5)
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Account
                    sectionLabel("ACCOUNT")

                    HStack(spacing: 14) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(SplitEZTheme.negative)
                        Text("Delete account")
                            .font(.subheadline)
                            .foregroundColor(SplitEZTheme.negative)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(SplitEZTheme.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                    .onTapGesture {}
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.top, 0)
            }
        }
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(SplitEZTheme.darkBg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func securityRow(icon: String, title: String, subtitle: String, @ViewBuilder trailing: () -> some View) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(SplitEZTheme.primary)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(SplitEZTheme.textSecondary)
            }
            Spacer()
            trailing()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private func sessionRow(_ session: SessionInfo) -> some View {
        HStack(spacing: 14) {
            Image(systemName: session.isCurrentDevice ? "iphone" : "desktopcomputer")
                .font(.system(size: 16))
                .foregroundColor(SplitEZTheme.textSecondary)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.deviceName)
                    .font(.subheadline.weight(.medium))
                Text(session.subtitle)
                    .font(.caption)
                    .foregroundColor(session.isActive ? SplitEZTheme.positive : SplitEZTheme.textSecondary)
            }
            Spacer()
            if session.isCurrentDevice {
                Circle()
                    .fill(SplitEZTheme.positive)
                    .frame(width: 10, height: 10)
            } else {
                Button("Revoke") {}
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(SplitEZTheme.negative)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundColor(SplitEZTheme.primary)
            .tracking(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)
    }

    private var rowDivider: some View {
        Divider().padding(.leading, 56)
    }
}
