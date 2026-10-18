import Foundation

public struct MicroCMSProverbDTO: Decodable, Sendable {
    public let text: String
    public let origin: String
    /// microCMS select fields decode as an array (`["ca_da"]`); text fields arrive as a bare string.
    public let category: String

    private enum CodingKeys: String, CodingKey {
        case text, origin, category
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        text = try c.decode(String.self, forKey: .text)
        origin = try c.decode(String.self, forKey: .origin)
        if let single = try? c.decode(String.self, forKey: .category) {
            category = single
        } else {
            let many = try c.decode([String].self, forKey: .category)
            category = many.first ?? "cham_ngon"
        }
    }
}

public struct MicroCMSProverbListResponse: Decodable, Sendable {
    public let contents: [MicroCMSProverbDTO]
    public let totalCount: Int
}
