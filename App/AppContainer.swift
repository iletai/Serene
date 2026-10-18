import SwiftUI
import SwiftData
import Observation
import VNCalendarDomain
import VNCalendarData
import VNCalendarKit
import VNCalendarLunar

@Observable
@MainActor
public final class AppContainer {
    public static let shared = AppContainer()

    public let modelContainer: ModelContainer
    public let reminderRepository: ReminderRepositoryProtocol
    public let holidayRepository: HolidayRepositoryProtocol
    public let prayerRepository: PrayerRepositoryProtocol
    public let proverbRepository: ProverbRepositoryProtocol
    public let subscriptionManager: SubscriptionManager
    public let notificationEngine: SmartNotificationEngine

    public let getMonthCalendarUseCase: GetMonthCalendarUseCase
    public let scheduleReminderUseCase: ScheduleReminderUseCase
    public let naturalSearchUseCase: NaturalSearchUseCase
    public let evaluateFeatureGateUseCase: EvaluateFeatureGateUseCase

    public init(inMemory: Bool = false) {
        let config = AppConfiguration.current
        let container: ModelContainer
        do {
            // Gate CloudKit on entitlement at launch. Container is created once;
            // purchasing Pro later requires recreating it (see TODO below).
            container = try ModelContainerFactory.createContainer(
                inMemoryOnly: inMemory,
                cloudKitContainerIdentifier: config.cloudKitContainerIdentifier,
                appGroupIdentifier: config.appGroupIdentifier,
                cloudKitEnabled: SubscriptionManager.shared.entitlement.isPro
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
        self.modelContainer = container

        let microClient = MicroCMSClient(
            serviceDomain: config.microCMSServiceDomain,
            apiKey: config.microCMSApiKey,
            defaultsSuiteName: config.appGroupIdentifier
        )

        self.reminderRepository = SwiftDataReminderRepository(modelContainer: self.modelContainer)
        self.holidayRepository = HybridHolidayRepository(modelContainer: self.modelContainer, client: microClient)
        self.prayerRepository = LocalPrayerRepository()
        self.proverbRepository = HybridProverbRepository(client: microClient)
        self.subscriptionManager = SubscriptionManager.shared
        self.notificationEngine = SmartNotificationEngine.shared

        self.getMonthCalendarUseCase = GetMonthCalendarUseCase(
            reminderRepository: self.reminderRepository,
            holidayRepository: self.holidayRepository
        )
        self.scheduleReminderUseCase = ScheduleReminderUseCase(
            reminderRepository: self.reminderRepository,
            subscriptionRepository: self.subscriptionManager
        )
        self.naturalSearchUseCase = NaturalSearchUseCase(
            reminderRepository: self.reminderRepository,
            holidayRepository: self.holidayRepository
        )
        self.evaluateFeatureGateUseCase = EvaluateFeatureGateUseCase(
            subscriptionRepository: self.subscriptionManager,
            reminderRepository: self.reminderRepository
        )
    }

    /// Refreshes proverbs from microCMS and pushes them into the calendar's quote source.
    /// Never throws: offline/failed sync must not break callers' status messaging.
    public func syncProverbs() async {
        try? await proverbRepository.synchronizeRemoteContent()
        guard let proverbs = try? await proverbRepository.fetchProverbs() else { return }
        VNFolkQuotes.source = proverbs.map {
            VNFolkQuote(quote: $0.text, authorOrOrigin: $0.origin)
        }
    }
}
