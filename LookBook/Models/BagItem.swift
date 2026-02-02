import Foundation
import SwiftData

@Model
final class BagItem {
    var id: UUID
    var productId: UUID
    var productTitle: String
    var productImageUrl: String
    var productPrice: Double
    var selectedSize: String
    var addedAt: Date

    init(
        id: UUID = UUID(),
        productId: UUID,
        productTitle: String,
        productImageUrl: String,
        productPrice: Double,
        selectedSize: String,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.productId = productId
        self.productTitle = productTitle
        self.productImageUrl = productImageUrl
        self.productPrice = productPrice
        self.selectedSize = selectedSize
        self.addedAt = addedAt
    }
}
