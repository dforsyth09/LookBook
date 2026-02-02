import SwiftUI
import SwiftData

struct FeedScreen: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedCategory = "all"
    @State private var products: [CachedProduct] = []
    @State private var currentPage = 0
    @State private var hasMore = true
    @State private var navigateToProduct: CachedProduct?

    private let theme = ThemeManager.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CategoryPicker(selected: $selectedCategory, accentColor: theme.accentColor)
                    .padding(.vertical, 12)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 20) {
                        ForEach(products) { product in
                            ProductCard(
                                product: product,
                                accentColor: theme.accentColor,
                                onHeart: { heartProduct(product) },
                                onTap: { navigateToProduct = product }
                            )
                            .onAppear {
                                if product.id == products.last?.id {
                                    loadMore()
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationDestination(item: $navigateToProduct) { product in
                ProductDetailScreen(product: product)
            }
        }
        .onAppear { loadInitial() }
        .onChange(of: selectedCategory) { _, _ in
            loadInitial()
        }
    }

    private var cacheManager: CacheManager {
        CacheManager(modelContext: modelContext)
    }

    private func loadInitial() {
        currentPage = 0
        let category = selectedCategory == "all" ? nil : selectedCategory
        products = cacheManager.getProducts(category: category, page: 0)
        hasMore = products.count >= 20
    }

    private func loadMore() {
        guard hasMore else { return }
        currentPage += 1
        let category = selectedCategory == "all" ? nil : selectedCategory
        let newProducts = cacheManager.getProducts(category: category, page: currentPage)
        if newProducts.isEmpty {
            hasMore = false
        } else {
            products.append(contentsOf: newProducts)
        }
    }

    private func heartProduct(_ product: CachedProduct) {
        cacheManager.toggleHeart(product: product)
    }

    private func addToBag(_ product: CachedProduct) {
        cacheManager.addToBag(product: product, size: "L")
    }
}
