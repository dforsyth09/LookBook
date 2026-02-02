import SwiftUI
import SwiftData

@main
struct LookBookApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CachedProduct.self,
            BagItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var showWelcome = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .opacity(showWelcome ? 0 : 1)

                if showWelcome {
                    WelcomeScreen {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showWelcome = false
                        }
                    }
                    .transition(.opacity)
                }
            }
            .preferredColorScheme(.light)
            .statusBarHidden(true)
            .persistentSystemOverlays(.hidden)
            .onAppear {
                setupImageCache()
                seedDataIfNeeded()
                syncFromSupabase()
            }
        }
        .modelContainer(sharedModelContainer)
    }

    private func setupImageCache() {
        let cache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,   // 50 MB memory
            diskCapacity: 500 * 1024 * 1024      // 500 MB disk
        )
        URLCache.shared = cache
    }

    @MainActor
    private func seedDataIfNeeded() {
        let context = sharedModelContainer.mainContext
        CacheManager(modelContext: context).seedBundledProductsIfNeeded()
    }

    private func syncFromSupabase() {
        Task.detached {
            let products = await SupabaseService.shared.fetchProducts()
            if !products.isEmpty {
                await MainActor.run {
                    let context = sharedModelContainer.mainContext
                    CacheManager(modelContext: context).importProducts(products)
                }
            }
        }
    }
}

struct MainTabView: View {
    private let theme = ThemeManager.shared

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
        }
        .tint(theme.accentColor)
    }
}
