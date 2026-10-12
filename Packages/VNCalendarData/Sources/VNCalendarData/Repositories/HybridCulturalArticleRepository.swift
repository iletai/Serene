import Foundation
import SwiftData
import VNCalendarDomain

public final class HybridCulturalArticleRepository: CulturalArticleRepositoryProtocol, Sendable {
    private let dataActor: ArticleDataActor
    private let client: MicroCMSClient

    public init(modelContainer: ModelContainer, client: MicroCMSClient) {
        self.dataActor = ArticleDataActor(modelContainer: modelContainer)
        self.client = client
    }

    public func getArticles(category: CulturalCategory?) async throws -> [CulturalArticle] {
        try await dataActor.fetchArticles(category: category)
    }

    public func getArticle(slug: String) async throws -> CulturalArticle? {
        try await dataActor.fetchArticle(slug: slug)
    }

    public func synchronizeRemoteContent() async throws {
        // Fetch cultural articles from microCMS if needed
    }
}
