import Foundation
import SwiftData

@Model
final class CachedProduct {
    @Attribute(.unique) var id: UUID
    var source: String
    var sourceId: String
    var title: String
    var imageUrl: String
    var price: Double
    var category: String
    var brand: String?
    var fetchedAt: Date
    var isHearted: Bool = false

    init(
        id: UUID = UUID(),
        source: String,
        sourceId: String,
        title: String,
        imageUrl: String,
        price: Double,
        category: String,
        brand: String? = nil,
        fetchedAt: Date = Date(),
        isHearted: Bool = false
    ) {
        self.id = id
        self.source = source
        self.sourceId = sourceId
        self.title = title
        self.imageUrl = imageUrl
        self.price = price
        self.category = category
        self.brand = brand
        self.fetchedAt = fetchedAt
        self.isHearted = isHearted
    }
}
