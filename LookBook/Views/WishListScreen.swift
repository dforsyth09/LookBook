import SwiftUI
import SwiftData

struct WishListScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<CachedProduct> { $0.isHearted },
           sort: \CachedProduct.fetchedAt, order: .reverse)
    private var wishListItems: [CachedProduct]

    @State private var navigateToProduct: CachedProduct?
    @State private var showClearConfirmation = false

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
                    VStack(spacing: 0) {
                        ScrollView(showsIndicators: false) {
                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(wishListItems) { product in
                                    ZStack(alignment: .topTrailing) {
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

                                        // Remove button
                                        Button {
                                            removeFromWishList(product)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 26))
                                                .foregroundStyle(.white, .red)
                                                .shadow(radius: 2)
                                        }
                                        .padding(6)
                                    }
                                }
                            }
                            .padding()
                        }

                        Button {
                            showClearConfirmation = true
                        } label: {
                            Text("Remove All Items")
                                .font(.system(size: 22, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.red)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .confirmationDialog("Remove all items from your wish list?", isPresented: $showClearConfirmation, titleVisibility: .visible) {
                            Button("Remove All", role: .destructive) {
                                CacheManager(modelContext: modelContext).clearWishList()
                            }
                        }
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
                }
            }
        }
    }

    private func removeFromWishList(_ product: CachedProduct) {
        CacheManager(modelContext: modelContext).toggleHeart(product: product)
    }
}
