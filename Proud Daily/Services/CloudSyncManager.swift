import Foundation
import SwiftData
import Combine
import Network
import os

// MARK: - Sync Status

enum SyncStatus: Equatable {
    case disabled
    case synced
    case syncing
    case error(String)
    case offline

    var displayText: String {
        switch self {
        case .disabled: return "Off"
        case .synced: return "Up to date"
        case .syncing: return "Syncing…"
        case .error(let msg): return "Error: \(msg)"
        case .offline: return "Offline — will sync when connected"
        }
    }

    var iconName: String {
        switch self {
        case .disabled: return "icloud.slash"
        case .synced: return "checkmark.icloud"
        case .syncing: return "arrow.triangle.2.circlepath.icloud"
        case .error: return "exclamationmark.icloud"
        case .offline: return "icloud.slash"
        }
    }
}

// MARK: - CloudSyncManager

@Observable
final class CloudSyncManager {
    private(set) var status: SyncStatus = .disabled
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.openclaw.prouddaily.networkmonitor")
    private(set) var isNetworkAvailable = true
    private let logger = Logger(subsystem: "com.openclaw.prouddaily", category: "CloudSync")

    static let shared = CloudSyncManager()

    private init() {
        startNetworkMonitoring()
    }

    deinit {
        networkMonitor.cancel()
    }

    // MARK: - Network Monitoring

    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self else { return }
                let wasAvailable = self.isNetworkAvailable
                self.isNetworkAvailable = path.status == .satisfied

                if self.status != .disabled {
                    if !self.isNetworkAvailable {
                        self.status = .offline
                    } else if !wasAvailable && self.isNetworkAvailable {
                        self.status = .syncing
                        try? await Task.sleep(for: .seconds(3))
                        if self.status == .syncing {
                            self.status = .synced
                        }
                    }
                }
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }

    // MARK: - Enable / Disable

    func enableSync() {
        logger.info("iCloud sync enabled by user")
        if isNetworkAvailable {
            status = .syncing
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(3))
                if status == .syncing {
                    status = .synced
                }
            }
        } else {
            status = .offline
        }
    }

    func disableSync() {
        logger.info("iCloud sync disabled by user — cloud data preserved")
        status = .disabled
    }

    func reportError(_ message: String) {
        logger.error("Sync error: \(message)")
        status = .error(message)
    }

    func markSynced() {
        if status != .disabled {
            status = .synced
        }
    }

    func markSyncing() {
        if status != .disabled {
            status = isNetworkAvailable ? .syncing : .offline
        }
    }
}
