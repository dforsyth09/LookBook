import Foundation
import SwiftData

@Model
final class CachedProduct {
    @Attribute(.unique) var id: UUID
    var source: String
    var sourceId: String
    var title: String
    var imageUrl: String
    var additionalImageUrls: [String]
    var price: Double
    var category: String
    var brand: String?
    var colour: String?
    var isOnSale: Bool
    var sourceUrl: String?
    var fetchedAt: Date
    var isHearted: Bool = false

    init(
        id: UUID = UUID(),
        source: String,
        sourceId: String,
        title: String,
        imageUrl: String,
        additionalImageUrls: [String] = [],
        price: Double,
        category: String,
        brand: String? = nil,
        colour: String? = nil,
        isOnSale: Bool = false,
        sourceUrl: String? = nil,
        fetchedAt: Date = Date(),
        isHearted: Bool = false
    ) {
        self.id = id
        self.source = source
        self.sourceId = sourceId
        self.title = title
        self.imageUrl = imageUrl
        self.additionalImageUrls = additionalImageUrls
        self.price = price
        self.category = category
        self.brand = brand
        self.colour = colour
        self.isOnSale = isOnSale
        self.sourceUrl = sourceUrl
        self.fetchedAt = fetchedAt
        self.isHearted = isHearted
    }
}
