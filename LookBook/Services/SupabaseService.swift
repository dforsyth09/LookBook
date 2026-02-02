import Foundation

/// Stub service for Supabase integration.
/// Replace the implementation with the real Supabase Swift SDK once the backend is live
/// and the SPM dependency is added.
final class SupabaseService: Sendable {

    // MARK: - Configuration

    // TODO: Replace with your real Supabase project values
    private let projectUrl = "https://YOUR_PROJECT.supabase.co"
    private let anonKey = "YOUR_ANON_KEY"

    static let shared = SupabaseService()

    // MARK: - Remote model

    struct RemoteProduct: Decodable, Sendable {
        let id: UUID
        let source: String
        let sourceId: String
        let title: String
        let imageUrl: String
        let price: Double
        let category: String
        let brand: String?
        let isActive: Bool?

        enum CodingKeys: String, CodingKey {
            case id, source, title, price, category, brand
            case sourceId = "source_id"
            case imageUrl = "image_url"
            case isActive = "is_active"
        }
    }

    // MARK: - Fetch

    /// Fetches products from Supabase. Returns empty array on any failure (never throws to the UI).
    func fetchProducts(category: String? = nil, limit: Int = 50, offset: Int = 0) async -> [RemoteProduct] {
        // Guard against placeholder config
        guard !projectUrl.contains("YOUR_PROJECT") else { return [] }

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
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return [] }
            let decoder = JSONDecoder()
            return (try? decoder.decode([RemoteProduct].self, from: data)) ?? []
        } catch {
            return []
        }
    }
}
