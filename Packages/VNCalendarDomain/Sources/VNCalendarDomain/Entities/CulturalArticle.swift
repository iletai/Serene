import Foundation

public enum CulturalCategory: String, Codable, Sendable, CaseIterable {
    case tet = "tet"
    case leHoi = "le_hoi"
    case phongTuc = "phong_tuc"
    case amThuc = "am_thuc"

    public var title: String {
        switch self {
        case .tet: return "Tết Cổ Truyền"
        case .leHoi: return "Lễ Hội Dân Gian"
        case .phongTuc: return "Phong Tục & Nghi Lễ"
        case .amThuc: return "Ẩm Thực Truyền Thống"
        }
    }
}

public struct CulturalArticle: Identifiable, Equatable, Sendable, Codable {
    public let id: String
    public let title: String
    public let slug: String
    public let coverImageURL: String?
    public let contentHTML: String
    public let category: CulturalCategory
    public let publishedAt: Date
    public let updatedAt: Date

    public init(
        id: String,
        title: String,
        slug: String,
        coverImageURL: String? = nil,
        contentHTML: String,
        category: CulturalCategory = .phongTuc,
        publishedAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.slug = slug
        self.coverImageURL = coverImageURL
        self.contentHTML = contentHTML
        self.category = category
        self.publishedAt = publishedAt
        self.updatedAt = updatedAt
    }
}
