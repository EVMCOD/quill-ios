import Foundation
import SwiftData
import SwiftUI

/// Coordinator for every external integration. Quill ships with Obsidian only.
@MainActor
public final class IntegrationHub: ObservableObject {
    public static let shared = IntegrationHub()

    @Published public private(set) var obsidian: IntegrationState = .notConfigured
    @Published public private(set) var lastSync: Date?

    public enum IntegrationState: Equatable {
        case notConfigured, disconnected, syncing, error(String), ok

        public var label: String {
            switch self {
            case .notConfigured: return "Not configured"
            case .disconnected:  return "Disconnected"
            case .syncing:       return "Syncing…"
            case .error(let m):  return "Error: \(m)"
            case .ok:            return "Synced"
            }
        }
    }

    private let obsidianSync = ObsidianSyncService.shared

    private init() { refreshState() }

    public func refreshState() {
        obsidian = obsidianSync.isConfigured ? .ok : .notConfigured
    }

    public func refreshOnLaunch() {
        Task { await syncAll() }
    }

    public func scheduleBackgroundRefresh() {}

    public func syncAll() async {
        if obsidianSync.isConfigured {
            obsidian = .syncing
            Task { @MainActor in
                obsidianSync.sync(container: ArticleStore.shared.container)
                obsidian = .ok
                lastSync = .now
            }
        }
    }

    public func propagateToIntegrations(_ article: Article) async {
        if obsidianSync.isConfigured {
            Task { @MainActor in
                obsidianSync.sync(container: ArticleStore.shared.container)
                obsidian = .ok
                lastSync = .now
            }
        }
    }

    public func setObsidianVault(_ url: URL) {
        do {
            try obsidianSync.pickVault(url)
            refreshState()
        } catch {
            QLLog.obsidian.error("Vault set failed: \(error.localizedDescription)")
            obsidian = .error(error.localizedDescription)
        }
    }

    public func clearObsidianVault() {
        obsidianSync.clear()
        refreshState()
    }
}
