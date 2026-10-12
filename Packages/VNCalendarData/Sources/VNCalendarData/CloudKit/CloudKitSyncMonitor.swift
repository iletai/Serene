import Foundation
import Combine
import OSLog

public enum ICloudAccountStatus: Sendable {
    case unknown
    case available
    case noAccount
    case restricted
    case temporarilyUnavailable
}

public actor CloudKitSyncMonitor {
    public let containerIdentifier: String
    private let logger = Logger(subsystem: "com.iletai.annien", category: "CloudKitSyncMonitor")
    private var observationTask: Task<Void, Never>?

    public init(containerIdentifier: String) {
        self.containerIdentifier = containerIdentifier
        self.observationTask = nil
    }

    public func startObserving() {
        guard observationTask == nil else { return }
        observationTask = Task { [weak self] in
            let name = NSNotification.Name("NSPersistentStoreRemoteChangeNotification")
            for await _ in NotificationCenter.default.notifications(named: name) {
                guard let self else { break }
                await self.logRemoteChange()
            }
        }
    }

    public func stopObserving() {
        observationTask?.cancel()
        observationTask = nil
    }

    private func logRemoteChange() {
        logger.info("Received remote CloudKit database change notification.")
    }

    deinit {
        observationTask?.cancel()
    }
}
