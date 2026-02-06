import SwiftUI
import SwiftData

struct AdminDashboardScreen: View {
    @Environment(\.modelContext) private var modelContext

    @State private var linkedUserCart: [CartItemWithProduct] = []
    @State private var linkedUserWishlist: [AdminWishlistItem] = []
    @State private var linkedUserName: String = "User"
    @State private var isLoading = false
    @State private var pollingTask: Task<Void, Never>?

    private let theme = ThemeManager.shared
    private let pollingInterval: UInt64 = 10_000_000_000 // 10 seconds in nanoseconds

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
                                        CachedImageView(url: item.imageUrl)
                                            .frame(width: 70, height: 70)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.title)
                                                .font(.system(size: 18, weight: .semibold))
                                                .lineLimit(2)
                                            Text("Size: \(item.selectedSize)")
                                                .font(.system(size: 16))
                                                .foregroundStyle(.secondary)
                                            Text("$\(item.price, specifier: "%.2f")")
                                                .font(.system(size: 18, weight: .medium))
                                        }

                                        Spacer()

                                        if let sourceUrl = item.sourceUrl,
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
                                ForEach(linkedUserWishlist) { item in
                                    HStack(spacing: 12) {
                                        CachedImageView(url: item.imageUrl)
                                            .frame(width: 70, height: 70)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.title)
                                                .font(.system(size: 18, weight: .semibold))
                                                .lineLimit(2)
                                            if let brand = item.brand {
                                                Text(brand)
                                                    .font(.system(size: 16))
                                                    .foregroundStyle(.secondary)
                                            }
                                            Text("$\(item.price, specifier: "%.2f")")
                                                .font(.system(size: 18, weight: .medium))
                                        }

                                        Spacer()

                                        if let sourceUrl = item.sourceUrl,
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
            await loadLinkedUserData(showLoading: true)
            startPolling()
        }
        .onDisappear {
            pollingTask?.cancel()
        }
    }

    private func startPolling() {
        pollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: pollingInterval)
                if !Task.isCancelled {
                    await loadLinkedUserData()
                }
            }
        }
    }

    private func loadLinkedUserData(showLoading: Bool = false) async {
        guard let linkedUserId = AuthService.shared.linkedUserId else { return }

        if showLoading { isLoading = true }
        defer { if showLoading { isLoading = false } }

        // Fetch cart and wishlist items from Supabase
        let remoteCartItems = await SupabaseService.shared.fetchCartItems(userId: linkedUserId)
        let remoteWishlistItems = await SupabaseService.shared.fetchWishlistItems(userId: linkedUserId)

        // Collect all product IDs we need to fetch
        let cartProductIds = remoteCartItems.map { $0.productId }
        let wishlistProductIds = remoteWishlistItems.map { $0.productId }
        let allProductIds = Array(Set(cartProductIds + wishlistProductIds))

        // Fetch product details directly from Supabase
        let remoteProducts = await SupabaseService.shared.fetchProductsByIds(allProductIds)
        let productLookup = Dictionary(uniqueKeysWithValues: remoteProducts.map { ($0.id, $0) })

        await MainActor.run {
            linkedUserCart = remoteCartItems.compactMap { cartItem in
                guard let remoteProduct = productLookup[cartItem.productId] else { return nil }
                return CartItemWithProduct(
                    id: cartItem.id,
                    remoteProduct: remoteProduct,
                    selectedSize: cartItem.selectedSize
                )
            }

            linkedUserWishlist = remoteWishlistItems.compactMap { wishlistItem in
                guard let remoteProduct = productLookup[wishlistItem.productId] else { return nil }
                return AdminWishlistItem(remoteProduct: remoteProduct)
            }
        }
    }
}

struct CartItemWithProduct: Identifiable {
    let id: UUID
    let title: String
    let imageUrl: String
    let price: Double
    let brand: String?
    let sourceUrl: String?
    let selectedSize: String

    init(id: UUID, remoteProduct: SupabaseService.RemoteProduct, selectedSize: String) {
        self.id = id
        self.title = remoteProduct.title
        self.imageUrl = remoteProduct.imageUrl
        self.price = remoteProduct.price
        self.brand = remoteProduct.brand
        self.sourceUrl = remoteProduct.sourceUrl
        self.selectedSize = selectedSize
    }
}

struct AdminWishlistItem: Identifiable {
    let id: UUID
    let title: String
    let imageUrl: String
    let price: Double
    let brand: String?
    let sourceUrl: String?

    init(remoteProduct: SupabaseService.RemoteProduct) {
        self.id = remoteProduct.id
        self.title = remoteProduct.title
        self.imageUrl = remoteProduct.imageUrl
        self.price = remoteProduct.price
        self.brand = remoteProduct.brand
        self.sourceUrl = remoteProduct.sourceUrl
    }
}
