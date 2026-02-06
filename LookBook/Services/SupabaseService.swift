import Foundation

final class SupabaseService: Sendable {

    // MARK: - Configuration

    private let projectUrl = "https://flrfjcenzizjfssfmele.supabase.co"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZscmZqY2Vueml6amZzc2ZtZWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAwNDQ2MzQsImV4cCI6MjA4NTYyMDYzNH0.F4ahOU8I3s5VtexjVAJr3WSiwtU7YfPmzVHlfRBjU3U"

    static let shared = SupabaseService()

    private var isConfigured: Bool {
        !projectUrl.contains("YOUR_PROJECT")
    }

    // MARK: - Remote Models

    struct RemoteProduct: Decodable, Sendable {
        let id: UUID
        let source: String
        let sourceId: String
        let title: String
        let imageUrl: String
        let additionalImageUrls: [String]?
        let price: Double
        let category: String
        let brand: String?
        let colour: String?
        let isOnSale: Bool?
        let isSellingFast: Bool?
        let sourceUrl: String?
        let isActive: Bool?

        enum CodingKeys: String, CodingKey {
            case id, source, title, price, category, brand, colour
            case sourceId = "source_id"
            case imageUrl = "image_url"
            case additionalImageUrls = "additional_image_urls"
            case isOnSale = "is_on_sale"
            case isSellingFast = "is_selling_fast"
            case sourceUrl = "source_url"
            case isActive = "is_active"
        }
    }

    struct RemoteUser: Decodable, Sendable {
        let id: UUID
        let deviceId: String
        let displayName: String?
        let role: String
        let linkedUserId: UUID?
        let createdAt: Date
        let lastSeenAt: Date

        enum CodingKeys: String, CodingKey {
            case id, role
            case deviceId = "device_id"
            case displayName = "display_name"
            case linkedUserId = "linked_user_id"
            case createdAt = "created_at"
            case lastSeenAt = "last_seen_at"
        }
    }

    struct RemoteCartItem: Decodable, Sendable {
        let id: UUID
        let userId: UUID
        let productId: UUID
        let selectedSize: String
        let addedAt: Date

        enum CodingKeys: String, CodingKey {
            case id
            case userId = "user_id"
            case productId = "product_id"
            case selectedSize = "selected_size"
            case addedAt = "added_at"
        }
    }

    struct RemoteWishlistItem: Decodable, Sendable {
        let id: UUID
        let userId: UUID
        let productId: UUID
        let addedAt: Date

        enum CodingKeys: String, CodingKey {
            case id
            case userId = "user_id"
            case productId = "product_id"
            case addedAt = "added_at"
        }
    }

    // MARK: - JSON Decoder

    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    // MARK: - Products

    func fetchProducts(category: String? = nil, limit: Int = 50, offset: Int = 0) async -> [RemoteProduct] {
        guard isConfigured else { return [] }

        // Fetch products from all sources (Catherines, Roaman's, etc.)
        var urlString = "\(projectUrl)/rest/v1/clothing_items?select=*&is_active=eq.true&order=created_at.desc&limit=\(limit)&offset=\(offset)"
        if let category, category != "all" {
            urlString += "&category=eq.\(category)"
        }

        guard let url = URL(string: urlString) else { return [] }

        var request = URLRequest(url: url)
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                print("SupabaseService: HTTP error for category \(category ?? "all")")
                return []
            }
            let products = (try? decoder.decode([RemoteProduct].self, from: data)) ?? []
            print("SupabaseService: Fetched \(products.count) products for category \(category ?? "all")")
            return products
        } catch {
            print("SupabaseService: Error fetching products: \(error)")
            return []
        }
    }

    func fetchProductsByIds(_ ids: [UUID]) async -> [RemoteProduct] {
        guard isConfigured, !ids.isEmpty else { return [] }

        // Supabase uses "in" filter with parentheses format
        let idList = ids.map { "\"\($0.uuidString)\"" }.joined(separator: ",")
        let urlString = "\(projectUrl)/rest/v1/clothing_items?select=*&id=in.(\(idList))"

        guard let url = URL(string: urlString) else { return [] }

        var request = URLRequest(url: url)
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                print("SupabaseService: HTTP error fetching products by IDs")
                return []
            }
            return (try? decoder.decode([RemoteProduct].self, from: data)) ?? []
        } catch {
            print("SupabaseService: Error fetching products by IDs: \(error)")
            return []
        }
    }

    // MARK: - Users

    func fetchUser(deviceId: String) async -> RemoteUser? {
        guard isConfigured else { return nil }

        let urlString = "\(projectUrl)/rest/v1/users?device_id=eq.\(deviceId)&limit=1"
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            let users = try? decoder.decode([RemoteUser].self, from: data)
            return users?.first
        } catch {
            return nil
        }
    }

    func createUser(id: UUID, deviceId: String, displayName: String?) async {
        guard isConfigured else { return }

        let urlString = "\(projectUrl)/rest/v1/users"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        var body: [String: Any] = [
            "id": id.uuidString,
            "device_id": deviceId,
            "role": "user"
        ]
        if let displayName {
            body["display_name"] = displayName
        }

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await URLSession.shared.data(for: request)
    }

    func updateLastSeen(userId: UUID) async {
        guard isConfigured else { return }

        let urlString = "\(projectUrl)/rest/v1/users?id=eq.\(userId.uuidString)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["last_seen_at": ISO8601DateFormatter().string(from: Date())]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await URLSession.shared.data(for: request)
    }

    // MARK: - Cart

    func addCartItem(id: UUID, userId: UUID, productId: UUID, selectedSize: String) async {
        guard isConfigured else { return }

        let urlString = "\(projectUrl)/rest/v1/cart_items"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        let body: [String: Any] = [
            "id": id.uuidString,
            "user_id": userId.uuidString,
            "product_id": productId.uuidString,
            "selected_size": selectedSize
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await URLSession.shared.data(for: request)
    }

    func removeCartItem(id: UUID) async {
        guard isConfigured else { return }

        let urlString = "\(projectUrl)/rest/v1/cart_items?id=eq.\(id.uuidString)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        _ = try? await URLSession.shared.data(for: request)
    }

    func fetchCartItems(userId: UUID) async -> [RemoteCartItem] {
        guard isConfigured else { return [] }

        let urlString = "\(projectUrl)/rest/v1/cart_items?user_id=eq.\(userId.uuidString)&order=added_at.desc"
        guard let url = URL(string: urlString) else { return [] }

        var request = URLRequest(url: url)
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return [] }
            return (try? decoder.decode([RemoteCartItem].self, from: data)) ?? []
        } catch {
            return []
        }
    }

    func clearCart(userId: UUID) async {
        guard isConfigured else { return }

        let urlString = "\(projectUrl)/rest/v1/cart_items?user_id=eq.\(userId.uuidString)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        _ = try? await URLSession.shared.data(for: request)
    }

    // MARK: - Wishlist

    func addWishlistItem(id: UUID, userId: UUID, productId: UUID) async {
        guard isConfigured else { return }

        let urlString = "\(projectUrl)/rest/v1/wishlist_items"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        let body: [String: Any] = [
            "id": id.uuidString,
            "user_id": userId.uuidString,
            "product_id": productId.uuidString
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await URLSession.shared.data(for: request)
    }

    func removeWishlistItem(id: UUID) async {
        guard isConfigured else { return }

        let urlString = "\(projectUrl)/rest/v1/wishlist_items?id=eq.\(id.uuidString)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        _ = try? await URLSession.shared.data(for: request)
    }

    func fetchWishlistItems(userId: UUID) async -> [RemoteWishlistItem] {
        guard isConfigured else { return [] }

        let urlString = "\(projectUrl)/rest/v1/wishlist_items?user_id=eq.\(userId.uuidString)&order=added_at.desc"
        guard let url = URL(string: urlString) else { return [] }

        var request = URLRequest(url: url)
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return [] }
            return (try? decoder.decode([RemoteWishlistItem].self, from: data)) ?? []
        } catch {
            return []
        }
    }

    func clearWishlist(userId: UUID) async {
        guard isConfigured else { return }

        let urlString = "\(projectUrl)/rest/v1/wishlist_items?user_id=eq.\(userId.uuidString)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        _ = try? await URLSession.shared.data(for: request)
    }
}
