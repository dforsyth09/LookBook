import SwiftUI
import SwiftData

struct WishListScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<CachedProduct> { $0.isHearted },
           sort: \CachedProduct.fetchedAt, order: .reverse)
    private var wishListItems: [CachedProduct]

    @State private var navigateToProduct: CachedProduct?

    private let theme = ThemeManager.shared
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if wishListItems.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "heart")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("No saved items yet")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text("Tap the heart on items you love!")
                            .font(.system(size: 20))
                            .foregroundStyle(.tertiary)
                        Spacer()
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(wishListItems) { product in
                                Button {
                                    navigateToProduct = product
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        CachedImageView(url: product.imageUrl)
                                            .frame(height: 200)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))

                                        Text(product.title)
                                            .font(.system(size: 18, weight: .semibold))
                                            .lineLimit(2)
                                            .foregroundStyle(.primary)

                                        Text("$\(product.price, specifier: "%.2f")")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundStyle(.primary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationDestination(item: $navigateToProduct) { product in
                ProductDetailScreen(product: product)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Wish List")
                        .font(.system(size: 28, weight: .bold))
                        .onTapGesture(count: 3) {
                            CacheManager(modelContext: modelContext).clearWishList()
                        }
                }
            }
        }
    }
}
