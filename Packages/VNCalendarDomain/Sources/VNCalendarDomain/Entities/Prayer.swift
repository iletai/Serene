import Foundation

public enum PrayerCategory: String, Sendable, Codable, CaseIterable {
    case firstAndFullMoon = "Mùng 1 & Rằm"
    case ancestralDeath = "Giỗ Gia Tiên"
    case festivalAndLunarNewYear = "Lễ Tiết & Tết"
    case lifeEvents = "Nghi Lễ Gia Sự"
    case spiritualProtection = "Cầu An & Giải Hạn"

    public var iconName: String {
        switch self {
        case .firstAndFullMoon: return "moon.stars.fill"
        case .ancestralDeath: return "flame.fill"
        case .festivalAndLunarNewYear: return "sparkles"
        case .lifeEvents: return "house.fill"
        case .spiritualProtection: return "shield.lefthalf.filled"
        }
    }
}

public struct Prayer: Identifiable, Sendable, Codable, Equatable {
    public let id: String
    public let title: String
    public let category: PrayerCategory
    public let occasion: String
    public let offerings: [String]
    public let prayerText: String
    public let notes: String?
    public let tags: [String]

    public init(
        id: String,
        title: String,
        category: PrayerCategory,
        occasion: String,
        offerings: [String] = [],
        prayerText: String,
        notes: String? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.occasion = occasion
        self.offerings = offerings
        self.prayerText = prayerText
        self.notes = notes
        self.tags = tags
    }
}
