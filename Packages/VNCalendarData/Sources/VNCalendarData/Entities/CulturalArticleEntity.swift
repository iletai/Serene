import Foundation
import SwiftData
import VNCalendarDomain

@Model
public final class CulturalArticleEntity {
    public var id: String = ""
    public var title: String = ""
    public var slug: String = ""
    public var categoryRawValue: String = "phong_tuc"
    public var coverImageURL: String?
    public var contentHTML: String = ""
    public var publishedAt = Date()
    public var updatedAt = Date()

    public init(
        id: String = "",
        title: String = "",
        slug: String = "",
        categoryRawValue: String = "phong_tuc",
        coverImageURL: String? = nil,
        contentHTML: String = "",
        publishedAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.slug = slug
        self.categoryRawValue = categoryRawValue
        self.coverImageURL = coverImageURL
        self.contentHTML = contentHTML
        self.publishedAt = publishedAt
        self.updatedAt = updatedAt
    }

    public func toDomain() -> CulturalArticle {
        CulturalArticle(
            id: self.id,
            title: self.title,
            slug: self.slug,
            coverImageURL: self.coverImageURL,
            contentHTML: self.contentHTML,
            category: CulturalCategory(rawValue: self.categoryRawValue) ?? .phongTuc,
            publishedAt: self.publishedAt,
            updatedAt: self.updatedAt
        )
    }
}
