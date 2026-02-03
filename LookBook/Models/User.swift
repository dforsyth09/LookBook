import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: UUID
    var deviceId: String
    var displayName: String?
    var role: String
    var linkedUserId: UUID?
    var createdAt: Date
    var lastSeenAt: Date

    init(
        id: UUID = UUID(),
        deviceId: String,
        displayName: String? = nil,
        role: String = "user",
        linkedUserId: UUID? = nil,
        createdAt: Date = Date(),
        lastSeenAt: Date = Date()
    ) {
        self.id = id
        self.deviceId = deviceId
        self.displayName = displayName
        self.role = role
        self.linkedUserId = linkedUserId
        self.createdAt = createdAt
        self.lastSeenAt = lastSeenAt
    }

    var isAdmin: Bool {
        role == "admin"
    }
}
