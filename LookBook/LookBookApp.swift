import SwiftUI
import SwiftData

@main
struct LookBookApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CachedProduct.self,
            BagItem.self,
            User.self,
            WishlistItem.self,
            ViewedItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var showWelcome = true
    @State private var isDataReady = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isDataReady {
                    MainTabView()
                        .opacity(showWelcome ? 0 : 1)
                }

                if showWelcome {
                    WelcomeScreen {
                        // Only dismiss welcome if data is ready
                        if isDataReady {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                showWelcome = false
                            }
                        }
                    }
                    .transition(.opacity)
                }
            }
            .preferredColorScheme(.light)
            .statusBarHidden(true)
            .persistentSystemOverlays(.hidden)
            .task {
                setupImageCache()
                await initializeAuth()
                await syncFromSupabase()
                isDataReady = true
                // Auto-dismiss welcome after data loads
                try? await Task.sleep(for: .seconds(1))
                withAnimation(.easeInOut(duration: 0.4)) {
                    showWelcome = false
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }

    private func setupImageCache() {
        let cache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 500 * 1024 * 1024
        )
        URLCache.shared = cache
    }

    @MainActor
    private func initializeAuth() async {
        let context = sharedModelContainer.mainContext
        await AuthService.shared.initialize(modelContext: context)
    }

    @MainActor
    private func syncFromSupabase() async {
        let context = sharedModelContainer.mainContext
        let cacheManager = CacheManager(modelContext: context)

        let categories = ["dresses", "tops", "shoes", "accessories", "sweaters", "blouses", "plus-size"]
        let limit = 500

        // First, try to use the unseen-items RPC if user is logged in
        if let userId = AuthService.shared.currentUser?.id {
            var allProducts: [SupabaseService.RemoteProduct] = []
            for category in categories {
                let products = await SupabaseService.shared.fetchUnseenProducts(
                    userId: userId,
                    category: category,
                    limit: limit
                )
                allProducts.append(contentsOf: products)
            }

            if !allProducts.isEmpty {
                cacheManager.importProducts(allProducts)
                return
            }
            // Fall through to standard fetch if RPC not available yet
        }

        // Standard fetch with random offset so each launch gets different items
        var allProducts: [SupabaseService.RemoteProduct] = []
        for category in categories {
            // Use a random offset to rotate through the catalog
            let maxOffset = max(0, 1500 - limit) // conservative estimate per category
            let randomOffset = Int.random(in: 0...maxOffset)
            let products = await SupabaseService.shared.fetchProducts(
                category: category,
                limit: limit,
                offset: randomOffset
            )
            allProducts.append(contentsOf: products)

            // If random offset returned few results, backfill from offset 0
            if products.count < limit / 2 {
                let backfill = await SupabaseService.shared.fetchProducts(
                    category: category,
                    limit: limit - products.count,
                    offset: 0
                )
                allProducts.append(contentsOf: backfill)
            }
        }

        if !allProducts.isEmpty {
            cacheManager.importProducts(allProducts)
        } else {
            // Only seed bundled products if Supabase has no data (offline fallback)
            cacheManager.seedBundledProductsIfNeeded()
        }
    }
}

struct MainTabView: View {
    private let theme = ThemeManager.shared
    private var isAdmin: Bool { AuthService.shared.isAdmin }

    @State private var showDeviceId = false

    var body: some View {
        TabView {
            Tab("Shop", systemImage: "house.fill") {
                FeedScreen()
            }
            Tab("My Bag", systemImage: "bag.fill") {
                BagScreen()
            }
            Tab("Wish List", systemImage: "heart.fill") {
                WishListScreen()
            }
            if isAdmin {
                Tab("Admin", systemImage: "person.badge.key.fill") {
                    AdminDashboardScreen()
                }
            }
        }
        .tint(theme.accentColor)
        .alert("Device ID", isPresented: $showDeviceId) {
            Button("Copy") {
                UIPasteboard.general.string = AuthService.shared.deviceId
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(AuthService.shared.deviceId)
        }
    }
}
