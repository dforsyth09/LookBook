import Foundation
import SwiftData

@Observable
final class AuthService {
    static let shared = AuthService()

    private(set) var currentUser: User?
    private let deviceIdKey = "lookbook_device_id"

    var isAdmin: Bool {
        currentUser?.role == "admin"
    }

    var linkedUserId: UUID? {
        currentUser?.linkedUserId
    }

    var deviceId: String {
        getOrCreateDeviceId()
    }

    func initialize(modelContext: ModelContext) async {
        let deviceId = getOrCreateDeviceId()
        currentUser = await fetchOrCreateUser(deviceId: deviceId, modelContext: modelContext)
    }

    private func getOrCreateDeviceId() -> String {
        if let existing = UserDefaults.standard.string(forKey: deviceIdKey) {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: deviceIdKey)
        return newId
    }

    private func fetchOrCreateUser(deviceId: String, modelContext: ModelContext) async -> User? {
        // First check Supabase for existing user
        if let remoteUser = await SupabaseService.shared.fetchUser(deviceId: deviceId) {
            // Sync to local
            let user = User(
                id: remoteUser.id,
                deviceId: remoteUser.deviceId,
                displayName: remoteUser.displayName,
                role: remoteUser.role,
                linkedUserId: remoteUser.linkedUserId,
                createdAt: remoteUser.createdAt,
                lastSeenAt: Date()
            )
            await MainActor.run {
                // Check if already exists locally
                let descriptor = FetchDescriptor<User>(
                    predicate: #Predicate { $0.deviceId == deviceId }
                )
                if let existingLocal = try? modelContext.fetch(descriptor).first {
                    existingLocal.role = remoteUser.role
                    existingLocal.linkedUserId = remoteUser.linkedUserId
                    existingLocal.displayName = remoteUser.displayName
                    existingLocal.lastSeenAt = Date()
                } else {
                    modelContext.insert(user)
                }
                try? modelContext.save()
            }

            // Update last seen on server
            await SupabaseService.shared.updateLastSeen(userId: remoteUser.id)

            return user
        }

        // No remote user, check local
        let localUser: User? = await MainActor.run {
            let descriptor = FetchDescriptor<User>(
                predicate: #Predicate { $0.deviceId == deviceId }
            )
            return try? modelContext.fetch(descriptor).first
        }

        if let localUser {
            // Try to create on Supabase
            await SupabaseService.shared.createUser(
                id: localUser.id,
                deviceId: deviceId,
                displayName: localUser.displayName
            )
            return localUser
        }

        // Brand new user
        let newUser = User(deviceId: deviceId)
        await MainActor.run {
            modelContext.insert(newUser)
            try? modelContext.save()
        }

        // Create on Supabase
        await SupabaseService.shared.createUser(
            id: newUser.id,
            deviceId: deviceId,
            displayName: nil
        )

        return newUser
    }
}
