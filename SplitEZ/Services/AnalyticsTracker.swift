import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Lightweight analytics tracker that batches events and sends them to the backend.
actor AnalyticsTracker {
    static let shared = AnalyticsTracker()

    private let api = APIClient.shared
    private var queue: [[String: Any]] = []
    private var sessionId: String = UUID().uuidString
    private let platform = "ios"
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

    // MARK: - Install tracking

    /// Persistent install ID stored in Keychain (survives app reinstalls).
    private var installId: String {
        let key = "splitez_install_id"
        if let existing = KeychainHelper.get(key) { return existing }
        let newId = UUID().uuidString
        KeychainHelper.set(newId, for: key)
        return newId
    }

    /// Register this device install with the backend. Call once per app launch.
    func registerInstall() async {
        var payload: [String: Any] = [
            "installId": installId,
            "platform": platform,
            "appVersion": appVersion,
        ]
        #if canImport(UIKit)
        let device = await UIDevice.current
        payload["osVersion"] = await device.systemVersion
        payload["deviceModel"] = await device.model
        #endif

        do {
            let _: SuccessResponse = try await api.post("/analytics/installs", body: AnyCodable(payload), auth: false)
        } catch {
            // Non-critical — silently ignore
        }
    }

    /// Call when the app launches or user logs in to start a new analytics session.
    func startSession() {
        sessionId = UUID().uuidString
        track(event: "app_open")
        Task { await registerInstall() }
    }

    /// Track a screen view.
    func trackScreen(_ screen: String) {
        track(event: "screen_view", screen: screen)
    }

    /// Track a user action.
    func trackAction(_ action: String, screen: String? = nil, metadata: [String: Any]? = nil) {
        track(event: "action", screen: screen, action: action, metadata: metadata)
    }

    /// Generic event tracking.
    func track(event: String, screen: String? = nil, action: String? = nil, metadata: [String: Any]? = nil) {
        var payload: [String: Any] = [
            "event": event,
            "sessionId": sessionId,
            "platform": platform,
            "appVersion": appVersion,
        ]
        if let screen = screen { payload["screen"] = screen }
        if let action = action { payload["action"] = action }
        // metadata skipped for simplicity in batch — can add if needed

        queue.append(payload)

        // Flush if we have 10+ events queued
        if queue.count >= 10 {
            Task { await flush() }
        }
    }

    /// Send queued events to the server.
    func flush() async {
        guard !queue.isEmpty else { return }
        let batch = queue
        queue = []

        let events = batch.map { dict -> TrackEventPayload in
            TrackEventPayload(
                event: dict["event"] as? String ?? "",
                sessionId: dict["sessionId"] as? String,
                screen: dict["screen"] as? String,
                action: dict["action"] as? String,
                platform: dict["platform"] as? String,
                appVersion: dict["appVersion"] as? String
            )
        }

        do {
            let _: SuccessResponse = try await api.post("/analytics/events/batch", body: BatchPayload(events: events), auth: false)
        } catch {
            // Re-queue on failure (drop if too many)
            if queue.count < 100 {
                queue.insert(contentsOf: batch, at: 0)
            }
        }
    }
}

private struct TrackEventPayload: Codable {
    let event: String
    let sessionId: String?
    let screen: String?
    let action: String?
    let platform: String?
    let appVersion: String?
}

private struct BatchPayload: Codable {
    let events: [TrackEventPayload]
}
