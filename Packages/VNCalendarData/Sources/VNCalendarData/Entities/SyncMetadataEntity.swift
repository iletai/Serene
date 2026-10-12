import Foundation
import SwiftData

@Model
public final class SyncMetadataEntity {
    public var endpoint: String = ""
    public var eTag: String?
    public var lastModified: String?
    public var lastSyncTimestamp = Date()

    public init(
        endpoint: String = "",
        eTag: String? = nil,
        lastModified: String? = nil,
        lastSyncTimestamp: Date = Date()
    ) {
        self.endpoint = endpoint
        self.eTag = eTag
        self.lastModified = lastModified
        self.lastSyncTimestamp = lastSyncTimestamp
    }
}
