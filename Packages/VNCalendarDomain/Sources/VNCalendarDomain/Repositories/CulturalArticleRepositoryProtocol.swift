import Foundation

public protocol CulturalArticleRepositoryProtocol: Sendable {
    func getArticles(category: CulturalCategory?) async throws -> [CulturalArticle]
    func getArticle(slug: String) async throws -> CulturalArticle?
    func synchronizeRemoteContent() async throws
}
