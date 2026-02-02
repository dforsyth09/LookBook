import Foundation
import SwiftData

@Observable
final class CacheManager {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getProducts(category: String?, page: Int, pageSize: Int = 20) -> [CachedProduct] {
        var descriptor = FetchDescriptor<CachedProduct>(
            sortBy: [SortDescriptor(\.fetchedAt, order: .reverse)]
        )
        if let category, category != "all" {
            descriptor.predicate = #Predicate { $0.category == category }
        }
        descriptor.fetchOffset = page * pageSize
        descriptor.fetchLimit = pageSize
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func allProductCount(category: String?) -> Int {
        var descriptor = FetchDescriptor<CachedProduct>()
        if let category, category != "all" {
            descriptor.predicate = #Predicate { $0.category == category }
        }
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    func addToBag(product: CachedProduct, size: String) {
        let pid = product.id
        let descriptor = FetchDescriptor<BagItem>(
            predicate: #Predicate { $0.productId == pid && $0.selectedSize == size }
        )
        let existing = (try? modelContext.fetchCount(descriptor)) ?? 0
        if existing > 0 { return }

        let item = BagItem(
            productId: product.id,
            productTitle: product.title,
            productImageUrl: product.imageUrl,
            productPrice: product.price,
            selectedSize: size
        )
        modelContext.insert(item)
        try? modelContext.save()
    }

    func toggleHeart(product: CachedProduct) {
        product.isHearted.toggle()
        try? modelContext.save()
    }

    func getWishListItems() -> [CachedProduct] {
        let descriptor = FetchDescriptor<CachedProduct>(
            predicate: #Predicate { $0.isHearted },
            sortBy: [SortDescriptor(\.fetchedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func getBagItems() -> [BagItem] {
        let descriptor = FetchDescriptor<BagItem>(
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func clearBag() {
        let items = getBagItems()
        for item in items {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }

    func clearWishList() {
        let items = getWishListItems()
        for item in items {
            item.isHearted = false
        }
        try? modelContext.save()
    }

    func product(byId id: UUID) -> CachedProduct? {
        var descriptor = FetchDescriptor<CachedProduct>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    func seedBundledProductsIfNeeded() {
        let count = (try? modelContext.fetchCount(FetchDescriptor<CachedProduct>())) ?? 0
        if count > 0 { return }

        guard let url = Bundle.main.url(forResource: "BundledProducts", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return }

        struct BundledItem: Decodable {
            let title: String
            let imageUrl: String
            let price: Double
            let category: String
            let brand: String?
        }

        guard let items = try? JSONDecoder().decode([BundledItem].self, from: data) else { return }

        for item in items {
            let product = CachedProduct(
                source: "bundled",
                sourceId: UUID().uuidString,
                title: item.title,
                imageUrl: item.imageUrl,
                price: item.price,
                category: item.category,
                brand: item.brand
            )
            modelContext.insert(product)
        }
        try? modelContext.save()
    }

    func importProducts(_ remoteProducts: [SupabaseService.RemoteProduct]) {
        for rp in remoteProducts {
            let rpSource = rp.source
            let rpSourceId = rp.sourceId
            var descriptor = FetchDescriptor<CachedProduct>(
                predicate: #Predicate { $0.source == rpSource && $0.sourceId == rpSourceId }
            )
            descriptor.fetchLimit = 1
            let exists = (try? modelContext.fetchCount(descriptor)) ?? 0
            if exists > 0 { continue }

            let product = CachedProduct(
                id: rp.id,
                source: rp.source,
                sourceId: rp.sourceId,
                title: rp.title,
                imageUrl: rp.imageUrl,
                price: rp.price,
                category: rp.category,
                brand: rp.brand
            )
            modelContext.insert(product)
        }
        try? modelContext.save()
    }
}
