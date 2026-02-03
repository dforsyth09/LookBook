# iOS App Updates Plan — User Accounts & New Fields

This document outlines the changes needed in the iOS app to support:
1. Linked user/admin accounts
2. New product fields (colour, additional images, on sale, source URL)
3. Cart/wishlist sync to Supabase

---

## 1. Data Model Updates

### Update `CachedProduct` model

Add new fields from ASOS:

```swift
@Model class CachedProduct {
    @Attribute(.unique) var id: UUID
    var source: String
    var sourceId: String
    var title: String
    var imageUrl: String
    var additionalImageUrls: [String]  // NEW: Array of extra image URLs
    var price: Double
    var category: String
    var brand: String?
    var colour: String?                 // NEW: Color name
    var isOnSale: Bool                  // NEW: Sale flag
    var sourceUrl: String?              // NEW: ASOS product URL (for admin purchase)
    var fetchedAt: Date
}
```

### New `User` model

```swift
@Model class User {
    @Attribute(.unique) var id: UUID
    var deviceId: String
    var displayName: String?
    var role: String                    // "user" or "admin"
    var linkedUserId: UUID?             // For admins: the user they monitor
    var createdAt: Date
    var lastSeenAt: Date
}
```

### Update `BagItem` model

```swift
@Model class BagItem {
    var id: UUID
    var userId: UUID                    // NEW: Link to user
    var productId: UUID                 // Reference to CachedProduct
    var selectedSize: String
    var addedAt: Date
}
```

### New `WishlistItem` model

```swift
@Model class WishlistItem {
    var id: UUID
    var userId: UUID
    var productId: UUID
    var addedAt: Date
}
```

---

## 2. New Services

### `AuthService`

Handles device-based authentication (no login UI for regular users).

```swift
class AuthService {
    static let shared = AuthService()

    private(set) var currentUser: User?
    private let deviceIdKey = "lookbook_device_id"

    /// Called on app launch. Creates user if first launch.
    func initialize() async {
        let deviceId = getOrCreateDeviceId()
        currentUser = await fetchOrCreateUser(deviceId: deviceId)
    }

    private func getOrCreateDeviceId() -> String {
        if let existing = UserDefaults.standard.string(forKey: deviceIdKey) {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: deviceIdKey)
        return newId
    }

    private func fetchOrCreateUser(deviceId: String) async -> User {
        // Check Supabase for existing user
        // If not found, create new user with role = "user"
        // Return the user
    }

    var isAdmin: Bool {
        currentUser?.role == "admin"
    }

    var linkedUserId: UUID? {
        currentUser?.linkedUserId
    }
}
```

### `CartSyncService`

Syncs cart to Supabase so admin can see it.

```swift
class CartSyncService {
    func addToCart(product: CachedProduct, size: String) async {
        // 1. Save to local SwiftData
        // 2. Sync to Supabase cart_items table
    }

    func removeFromCart(item: BagItem) async {
        // 1. Remove from local SwiftData
        // 2. Remove from Supabase
    }

    func fetchLinkedUserCart() async -> [BagItem] {
        // For admin: fetch cart of linked user from Supabase
    }
}
```

---

## 3. UI Updates

### Product Card Updates

- Add **"SALE"** badge (red, top-left corner) when `isOnSale == true`
- Display **colour** below product name in smaller text

```swift
// In ProductCard.swift
if product.isOnSale {
    Text("SALE")
        .font(.caption.bold())
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.red)
        .cornerRadius(4)
}

if let colour = product.colour {
    Text(colour)
        .font(.subheadline)
        .foregroundColor(.secondary)
}
```

### Product Detail Screen Updates

- Add **image carousel** using `additionalImageUrls`
- Swipe horizontally through all product images
- Page indicator dots at bottom

```swift
// In ProductDetailScreen.swift
TabView {
    AsyncImage(url: URL(string: product.imageUrl))
    ForEach(product.additionalImageUrls, id: \.self) { url in
        AsyncImage(url: URL(string: url))
    }
}
.tabViewStyle(.page)
.frame(height: 400)
```

### Admin Mode (New Screen)

Only visible when `AuthService.shared.isAdmin == true`.

**AdminDashboardScreen:**
- Shows linked user's display name
- Lists their cart items with:
  - Product image, name, size, price
  - **"Buy" button** — opens `sourceUrl` in Safari
- Lists their wishlist items
- Pull-to-refresh to sync latest data

```swift
struct AdminDashboardScreen: View {
    @State private var linkedUserCart: [CartItemWithProduct] = []

    var body: some View {
        List {
            Section("Cart") {
                ForEach(linkedUserCart) { item in
                    HStack {
                        AsyncImage(url: item.product.imageUrl)
                            .frame(width: 60, height: 60)
                        VStack(alignment: .leading) {
                            Text(item.product.title)
                            Text("Size: \(item.selectedSize)")
                            Text("$\(item.product.price, specifier: "%.2f")")
                        }
                        Spacer()
                        if let url = item.product.sourceUrl {
                            Link("Buy", destination: URL(string: url)!)
                        }
                    }
                }
            }
        }
        .navigationTitle("Mom's Cart")
    }
}
```

### Navigation Updates

- If `isAdmin`: Show Admin tab in tab bar (or a gear icon that opens AdminDashboardScreen)
- Regular users never see admin UI

---

## 4. App Flow Changes

### First Launch (Regular User - Mom)

1. App launches → `AuthService.initialize()`
2. New device ID generated, saved to UserDefaults
3. User record created in Supabase with `role = "user"`
4. App proceeds to Welcome Screen as normal
5. Cart/wishlist actions sync to Supabase in background

### First Launch (Admin - You)

1. Same flow as above, creates user with `role = "user"`
2. You manually run SQL to upgrade to admin and link accounts:
   ```sql
   SELECT link_admin_to_user('your-device-id', 'her-device-id');
   ```
3. Next app launch detects `role = "admin"` and shows Admin tab

### Getting Device IDs

Add a hidden gesture (e.g., 10-tap on app logo) that shows current device ID:
```swift
.onTapGesture(count: 10) {
    showDeviceId = true
}

.alert("Device ID", isPresented: $showDeviceId) {
    Button("Copy") {
        UIPasteboard.general.string = AuthService.shared.currentUser?.deviceId
    }
    Button("OK", role: .cancel) {}
} message: {
    Text(AuthService.shared.currentUser?.deviceId ?? "Unknown")
}
```

---

## 5. Implementation Order

1. **Update data models** — Add new fields to CachedProduct, create User model
2. **Implement AuthService** — Device ID generation, user creation
3. **Update SupabaseService** — Add user/cart/wishlist table operations
4. **Update ProductCard** — Sale badge, colour display
5. **Update ProductDetailScreen** — Image carousel
6. **Implement CartSyncService** — Local + remote cart sync
7. **Build AdminDashboardScreen** — Admin-only view of linked user's cart
8. **Add hidden device ID display** — For initial setup
9. **Test full flow** — Both user and admin perspectives

---

## 6. Manual Setup Steps (One-Time)

After both devices have launched the app at least once:

1. Get **her device ID** from her phone (10-tap gesture)
2. Get **your device ID** from your phone
3. Run in Supabase SQL Editor:
   ```sql
   SELECT link_admin_to_user('YOUR-DEVICE-ID', 'HER-DEVICE-ID');
   ```
4. Restart your app — Admin tab should now appear

---

## 7. Security Notes

- Regular users cannot see admin UI (role check in SwiftUI)
- RLS policies prevent users from accessing other users' data
- Admin can only read (not modify) linked user's cart
- Source URLs are only displayed in admin mode, never in regular user mode
