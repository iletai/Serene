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
        #if DEV
        return AppConfiguration(
            bundleIdentifier: "com.iletai.annien.dev",
            appGroupIdentifier: "group.com.iletai.annien.dev",
            cloudKitContainerIdentifier: "iCloud.com.iletai.annien.dev",
            microCMSServiceDomain: "annien",
            microCMSApiKey: infoDict["MICROCMS_API_KEY"] as? String ?? ""
        )
        #else
        return AppConfiguration(
            bundleIdentifier: "com.iletai.annien",
            appGroupIdentifier: "group.com.iletai.annien",
            cloudKitContainerIdentifier: "iCloud.com.iletai.annien",
            microCMSServiceDomain: "annien",
            microCMSApiKey: infoDict["MICROCMS_API_KEY"] as? String ?? ""
        )
        #endif
    }
}
