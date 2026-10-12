import Foundation
import SwiftData
import VNCalendarDomain

/// Schema version 1. Freeze the entity list here so future versions can diff against it.
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

/// Single-version plan: add `AppSchemaV2` + a `MigrationStage.lightweight` entry in `stages`
/// when the schema first changes.
public enum AppSchemaMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [AppSchemaV1.self]
    }

    public static var stages: [MigrationStage] {
        []
    }
}

public enum ModelContainerFactory {
    public static func createContainer(
        inMemoryOnly: Bool = false,
        cloudKitContainerIdentifier: String = "iCloud.com.iletai.annien",
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