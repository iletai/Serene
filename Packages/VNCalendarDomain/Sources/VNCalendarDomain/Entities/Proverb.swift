import Foundation

/// A proverb / folk saying managed via microCMS.
public struct Proverb: Sendable, Equatable, Codable {
    public let text: String
    public let origin: String
    /// microCMS select raw value: ca_da | tuc_ngu | cham_ngon | trieu_ly.
    public let category: String

    public init(text: String, origin: String, category: String) {
        self.text = text
        self.origin = origin
        self.category = category
    }
}
