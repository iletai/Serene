import Foundation

public struct AppConfiguration: Sendable {
    public let bundleIdentifier: String
    public let appGroupIdentifier: String
    public let cloudKitContainerIdentifier: String
    public let microCMSServiceDomain: String
    public let microCMSApiKey: String

    public init(
        bundleIdentifier: String,
        appGroupIdentifier: String,
        cloudKitContainerIdentifier: String,
        microCMSServiceDomain: String,
        microCMSApiKey: String
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.appGroupIdentifier = appGroupIdentifier
        self.cloudKitContainerIdentifier = cloudKitContainerIdentifier
        self.microCMSServiceDomain = microCMSServiceDomain
        self.microCMSApiKey = microCMSApiKey
    }

    public static var current: AppConfiguration {
        let infoDict = Bundle.main.infoDictionary ?? [:]
        // Service domain is single-source in Config/*.xcconfig
        // (MICROCMS_SERVICE_DOMAIN -> Info.plist) so envs can diverge
        // without touching Swift. Fallback matches the live tenant.
        let serviceDomain = infoDict["MICROCMS_SERVICE_DOMAIN"] as? String ?? "annien"
        let apiKey = infoDict["MICROCMS_API_KEY"] as? String ?? ""
        #if DEV
        return AppConfiguration(
            bundleIdentifier: "com.iletai.annien.dev",
            appGroupIdentifier: "group.com.iletai.annien.dev",
            cloudKitContainerIdentifier: "iCloud.com.iletai.annien.dev",
            microCMSServiceDomain: serviceDomain,
            microCMSApiKey: apiKey
        )
        #else
        return AppConfiguration(
            bundleIdentifier: "com.iletai.annien",
            appGroupIdentifier: "group.com.iletai.annien",
            cloudKitContainerIdentifier: "iCloud.com.iletai.annien",
            microCMSServiceDomain: serviceDomain,
            microCMSApiKey: apiKey
        )
        #endif
    }
}
