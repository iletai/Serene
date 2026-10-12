import Foundation
import SwiftData
import VNCalendarDomain

@ModelActor
public actor ArticleDataActor {
    public func fetchArticles(category: CulturalCategory?) throws -> [CulturalArticle] {
        if let targetCategory = category?.rawValue {
            let descriptor = FetchDescriptor<CulturalArticleEntity>(
                predicate: #Predicate<CulturalArticleEntity> { entity in
                    entity.categoryRawValue == targetCategory
                },
                sortBy: [SortDescriptor(\.publishedAt, order: .reverse)]
            )
            return try modelContext.fetch(descriptor).map { $0.toDomain() }
        } else {
            let descriptor = FetchDescriptor<CulturalArticleEntity>(
                sortBy: [SortDescriptor(\.publishedAt, order: .reverse)]
            )
            return try modelContext.fetch(descriptor).map { $0.toDomain() }
        }
    }

    public func fetchArticle(slug: String) throws -> CulturalArticle? {
        let targetSlug = slug
        let descriptor = FetchDescriptor<CulturalArticleEntity>(
            predicate: #Predicate<CulturalArticleEntity> { $0.slug == targetSlug }
        )
        return try modelContext.fetch(descriptor).first?.toDomain()
    }
}
