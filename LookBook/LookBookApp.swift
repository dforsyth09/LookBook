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
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var showWelcome = true
    @State private var isInitialized = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isInitialized {
                    MainTabView()
                        .opacity(showWelcome ? 0 : 1)
                }

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
            .task {
                setupImageCache()
                await initializeAuth()
                seedDataIfNeeded()
                syncFromSupabase()
                isInitialized = true
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
