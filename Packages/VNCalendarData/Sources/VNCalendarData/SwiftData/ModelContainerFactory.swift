import Foundation
import SwiftData
import VNCalendarDomain

/// Schema version 1. Freeze the entity list here so future versions can diff against it.
/// Note: two VersionedSchema enums cannot share the same @Model classes —
/// SwiftData computes a checksum per class set and rejects duplicates.
/// `ReminderItemEntity.isDeleted` (added with a default) migrates via
/// automatic lightweight migration; bump a real V2 only for non-lightweight changes.
public enum AppSchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version { .init(1, 0, 0) }

    public static var models: [any PersistentModel.Type] {
        [
            ReminderItemEntity.self,
            HolidayEntity.self,
            // CulturalArticleEntity stays for schema compatibility with already-synced CloudKit
            // stores. Removing it from the schema is a destructive migration, not a cleanup.
            CulturalArticleEntity.self,
            SyncMetadataEntity.self
        ]
    }
}

public enum AppSchemaMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [AppSchemaV1.self]
    }

    public static var stages: [MigrationStage] {
        []
    }
}

public enum ModelContainerFactory {
    // cloudKitContainerIdentifier is required (no default): a silent prod
    // container default lets a forgotten argument write DEV data into prod.
    public static func createContainer(
        inMemoryOnly: Bool = false,
        cloudKitContainerIdentifier: String,
        appGroupIdentifier: String? = nil,
        cloudKitEnabled: Bool = true
    ) throws -> ModelContainer {
        let schema = Schema(versionedSchema: AppSchemaV1.self)

        if inMemoryOnly {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(
                for: schema,
                migrationPlan: AppSchemaMigrationPlan.self,
                configurations: config
            )
        }

        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase = cloudKitEnabled
            ? .private(cloudKitContainerIdentifier)
            : .none

        let config: ModelConfiguration
        if let appGroup = appGroupIdentifier,
           let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) {
            let storeURL = groupURL.appendingPathComponent("AnNien.store")
            config = ModelConfiguration(
                schema: schema,
                url: storeURL,
                cloudKitDatabase: cloudKitDatabase
            )
        } else {
            config = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: cloudKitDatabase
            )
        }

        return try ModelContainer(
            for: schema,
            migrationPlan: AppSchemaMigrationPlan.self,
            configurations: config
        )
    }
}