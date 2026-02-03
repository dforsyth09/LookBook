import Foundation
import SwiftData

@Model
final class WishlistItem {
    var id: UUID
    var userId: UUID?
    var productId: UUID
    var addedAt: Date
    var syncedToSupabase: Bool

    init(
        id: UUID = UUID(),
        userId: UUID? = nil,
        productId: UUID,
        addedAt: Date = Date(),
        syncedToSupabase: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.productId = productId
        self.addedAt = addedAt
        self.syncedToSupabase = syncedToSupabase
    }
}
