import SwiftUI
import SwiftData
import Observation
import OSLog
import VNCalendarDomain
import VNCalendarData
import VNCalendarKit
import VNCalendarLunar

@Observable
@MainActor
public final class AppContainer {
    public static let shared = AppContainer()

    private let logger = Logger(subsystem: "com.iletai.annien", category: "AppContainer")

    // Store-bound properties are `var`: an entitlement upgrade reopens the store.
    public private(set) var modelContainer: ModelContainer
    public private(set) var reminderRepository: ReminderRepositoryProtocol
    public private(set) var holidayRepository: HolidayRepositoryProtocol
    public let prayerRepository: PrayerRepositoryProtocol
    public let proverbRepository: ProverbRepositoryProtocol
    public let subscriptionManager: SubscriptionManager
    public let notificationEngine: SmartNotificationEngine

    public private(set) var getMonthCalendarUseCase: GetMonthCalendarUseCase
    public private(set) var scheduleReminderUseCase: ScheduleReminderUseCase
    public private(set) var naturalSearchUseCase: NaturalSearchUseCase
    public private(set) var evaluateFeatureGateUseCase: EvaluateFeatureGateUseCase

    private let inMemory: Bool
    private let microClient: MicroCMSClient

    public init(inMemory: Bool = false) {
        self.inMemory = inMemory
        let config = AppConfiguration.current
        let client = MicroCMSClient(
            serviceDomain: config.microCMSServiceDomain,
            apiKey: config.microCMSApiKey,
            defaultsSuiteName: config.appGroupIdentifier
        )
        self.microClient = client

        let sub = SubscriptionManager.shared

        self.subscriptionManager = sub
        self.notificationEngine = SmartNotificationEngine.shared
        self.prayerRepository = LocalPrayerRepository()
        self.proverbRepository = HybridProverbRepository(client: client)

        let graph = Self.makeStoreGraph(
            inMemory: inMemory,
            cloudKitEnabled: sub.entitlement.isPro,
            microClient: client,
            subscriptionManager: sub
        )
        self.modelContainer = graph.modelContainer
        self.reminderRepository = graph.reminderRepository
        self.holidayRepository = graph.holidayRepository
        self.getMonthCalendarUseCase = graph.getMonthCalendarUseCase
        self.scheduleReminderUseCase = graph.scheduleReminderUseCase
        self.naturalSearchUseCase = graph.naturalSearchUseCase
        self.evaluateFeatureGateUseCase = graph.evaluateFeatureGateUseCase

        // CloudKit is gated on entitlement at container creation, so a mid-session
        // free -> pro purchase must reopen the store (previously required relaunch).
        sub.onProUpgrade = { [weak self] in self?.rebuild() }
    }

    /// Reopens the store-bound graph with the current entitlement. Called when a
    /// purchase flips free -> pro so CloudKit sync turns on without relaunching.
    private func rebuild() {
        let graph = Self.makeStoreGraph(
            inMemory: inMemory,
            cloudKitEnabled: subscriptionManager.entitlement.isPro,
            microClient: microClient,
            subscriptionManager: subscriptionManager
        )
        modelContainer = graph.modelContainer
        reminderRepository = graph.reminderRepository
        holidayRepository = graph.holidayRepository
        getMonthCalendarUseCase = graph.getMonthCalendarUseCase
        scheduleReminderUseCase = graph.scheduleReminderUseCase
        naturalSearchUseCase = graph.naturalSearchUseCase
        evaluateFeatureGateUseCase = graph.evaluateFeatureGateUseCase
    }

    private struct StoreGraph {
        let modelContainer: ModelContainer
        let reminderRepository: ReminderRepositoryProtocol
        let holidayRepository: HolidayRepositoryProtocol
        let getMonthCalendarUseCase: GetMonthCalendarUseCase
        let scheduleReminderUseCase: ScheduleReminderUseCase
        let naturalSearchUseCase: NaturalSearchUseCase
        let evaluateFeatureGateUseCase: EvaluateFeatureGateUseCase
    }

    private static func makeStoreGraph(
        inMemory: Bool,
        cloudKitEnabled: Bool,
        microClient: MicroCMSClient,
        subscriptionManager: SubscriptionManager
    ) -> StoreGraph {
        let config = AppConfiguration.current
        let container: ModelContainer
        do {
            container = try ModelContainerFactory.createContainer(
                inMemoryOnly: inMemory,
                cloudKitContainerIdentifier: config.cloudKitContainerIdentifier,
                appGroupIdentifier: config.appGroupIdentifier,
                cloudKitEnabled: cloudKitEnabled
            )
        } catch {
            // CloudKit store open/migrate can fail (network, schema, container mismatch).
            // Fall back to a local-only store so the app still launches.
            do {
                container = try ModelContainerFactory.createContainer(
                    inMemoryOnly: inMemory,
                    cloudKitContainerIdentifier: config.cloudKitContainerIdentifier,
                    appGroupIdentifier: config.appGroupIdentifier,
                    cloudKitEnabled: false
                )
            } catch {
                fatalError("Failed to initialize SwiftData ModelContainer even locally: \(error)")
            }
        }

        let reminderRepository = SwiftDataReminderRepository(modelContainer: container)
        let holidayRepository = HybridHolidayRepository(modelContainer: container, client: microClient)

        return StoreGraph(
            modelContainer: container,
            reminderRepository: reminderRepository,
            holidayRepository: holidayRepository,
            getMonthCalendarUseCase: GetMonthCalendarUseCase(
                reminderRepository: reminderRepository,
                holidayRepository: holidayRepository
            ),
            scheduleReminderUseCase: ScheduleReminderUseCase(
                reminderRepository: reminderRepository,
                subscriptionRepository: subscriptionManager
            ),
            naturalSearchUseCase: NaturalSearchUseCase(
                reminderRepository: reminderRepository,
                holidayRepository: holidayRepository
            ),
            evaluateFeatureGateUseCase: EvaluateFeatureGateUseCase(
                subscriptionRepository: subscriptionManager,
                reminderRepository: reminderRepository
            )
        )
    }

    /// Refreshes proverbs from microCMS and pushes them into the calendar's quote source.
    /// Never throws: offline/failed sync must not break callers' status messaging.
    public func syncProverbs() async {
        do {
            try await proverbRepository.synchronizeRemoteContent()
        } catch {
            logger.error("Proverb sync failed: \(error.localizedDescription)")
        }
        guard let proverbs = try? await proverbRepository.fetchProverbs() else {
            logger.error("Proverb fetch failed (cache and bundle both unavailable).")
            return
        }
        let quotes = proverbs.map { VNFolkQuote(quote: $0.text, authorOrOrigin: $0.origin) }
        guard quotes != VNFolkQuotes.source else { return }  // skip redundant cache invalidation
        VNFolkQuotes.source = quotes
    }
}
