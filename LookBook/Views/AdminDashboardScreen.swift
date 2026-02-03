import SwiftUI
import SwiftData

struct AdminDashboardScreen: View {
    @Environment(\.modelContext) private var modelContext

    @State private var linkedUserCart: [CartItemWithProduct] = []
    @State private var linkedUserWishlist: [CachedProduct] = []
    @State private var linkedUserName: String = "User"
    @State private var isLoading = false

    private let theme = ThemeManager.shared

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading...")
                        .font(.system(size: 20))
                } else if linkedUserCart.isEmpty && linkedUserWishlist.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("No items yet")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text("Items will appear here when added")
                            .font(.system(size: 18))
                            .foregroundStyle(.tertiary)
                        Spacer()
                    }
                } else {
                    List {
                        if !linkedUserCart.isEmpty {
                            Section {
                                ForEach(linkedUserCart) { item in
                                    HStack(spacing: 12) {
                                        CachedImageView(url: item.product.imageUrl)
                                            .frame(width: 70, height: 70)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.product.title)
                                                .font(.system(size: 18, weight: .semibold))
                                                .lineLimit(2)
                                            Text("Size: \(item.selectedSize)")
                                                .font(.system(size: 16))
                                                .foregroundStyle(.secondary)
                                            Text("$\(item.product.price, specifier: "%.2f")")
                                                .font(.system(size: 18, weight: .medium))
                                        }

                                        Spacer()

                                        if let sourceUrl = item.product.sourceUrl,
                                           let url = URL(string: sourceUrl) {
                                            Link(destination: url) {
                                                Text("Buy")
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundStyle(.white)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(theme.accentColor)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            } header: {
                                Text("Cart (\(linkedUserCart.count))")
                                    .font(.system(size: 20, weight: .bold))
                            }
                        }

                        if !linkedUserWishlist.isEmpty {
                            Section {
                                ForEach(linkedUserWishlist) { product in
                                    HStack(spacing: 12) {
                                        CachedImageView(url: product.imageUrl)
                                            .frame(width: 70, height: 70)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(product.title)
                                                .font(.system(size: 18, weight: .semibold))
                                                .lineLimit(2)
                                            if let brand = product.brand {
                                                Text(brand)
                                                    .font(.system(size: 16))
                                                    .foregroundStyle(.secondary)
                                            }
                                            Text("$\(product.price, specifier: "%.2f")")
                                                .font(.system(size: 18, weight: .medium))
                                        }

                                        Spacer()

                                        if let sourceUrl = product.sourceUrl,
                                           let url = URL(string: sourceUrl) {
                                            Link(destination: url) {
                                                Text("Buy")
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundStyle(.white)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(theme.accentColor)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            } header: {
                                Text("Wish List (\(linkedUserWishlist.count))")
                                    .font(.system(size: 20, weight: .bold))
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        await loadLinkedUserData()
                    }
                }
            }
            .navigationTitle("\(linkedUserName)'s Items")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("\(linkedUserName)'s Items")
                        .font(.system(size: 24, weight: .bold))
                }
            }
        }
        .task {
            await loadLinkedUserData()
        }
    }

    private func loadLinkedUserData() async {
        guard let linkedUserId = AuthService.shared.linkedUserId else { return }

        isLoading = true
        defer { isLoading = false }

        // Fetch cart items
        let remoteCartItems = await SupabaseService.shared.fetchCartItems(userId: linkedUserId)
        let remoteWishlistItems = await SupabaseService.shared.fetchWishlistItems(userId: linkedUserId)

        // Fetch products for cart items
        await MainActor.run {
            let cacheManager = CacheManager(modelContext: modelContext)

            linkedUserCart = remoteCartItems.compactMap { cartItem in
                if let product = cacheManager.product(byId: cartItem.productId) {
                    return CartItemWithProduct(
                        id: cartItem.id,
                        product: product,
                        selectedSize: cartItem.selectedSize
                    )
                }
                return nil
            }

            linkedUserWishlist = remoteWishlistItems.compactMap { wishlistItem in
                cacheManager.product(byId: wishlistItem.productId)
            }
        }

        // Fetch user display name
        if let remoteUser = await SupabaseService.shared.fetchUser(deviceId: "") {
            // This is a workaround - ideally we'd have a fetchUserById
        }
    }
}

struct CartItemWithProduct: Identifiable {
    let id: UUID
    let product: CachedProduct
    let selectedSize: String
}
