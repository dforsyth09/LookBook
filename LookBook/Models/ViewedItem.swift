import Foundation
import SwiftData

@Model
final class ViewedItem {
    @Attribute(.unique) var productId: UUID
    var viewedAt: Date
    var syncedToServer: Bool

    init(productId: UUID, viewedAt: Date = Date(), syncedToServer: Bool = false) {
        self.productId = productId
        self.viewedAt = viewedAt
        self.syncedToServer = syncedToServer
    }
}
