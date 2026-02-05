import SwiftUI

struct ProductDetailScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let product: CachedProduct

    @State private var selectedSize = ""
    @State private var showConfetti = false

    private let theme = ThemeManager.shared

    private var defaultSize: String {
        product.category == "shoes" ? "8" : "L"
    }

    private var allImageUrls: [String] {
        [product.imageUrl] + product.additionalImageUrls
    }

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Image carousel
                    TabView {
                        ForEach(allImageUrls, id: \.self) { url in
                            CachedImageView(url: url)
                                .frame(maxWidth: .infinity)
                                .frame(height: 450)
                                .clipped()
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .frame(height: 450)

                    VStack(alignment: .leading, spacing: 12) {
                        // Badges
                        HStack(spacing: 8) {
                            if product.isOnSale {
                                Text("SALE")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            if product.isSellingFast {
                                HStack(spacing: 4) {
                                    Image(systemName: "flame.fill")
                                    Text("SELLING FAST")
                                }
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.orange)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }

                        Text(product.title)
                            .font(.system(size: 28, weight: .bold))

                        if let brand = product.brand {
                            Text(brand)
                                .font(.system(size: 20))
                                .foregroundStyle(.secondary)
                        }

                        if let colour = product.colour {
                            Text(colour)
                                .font(.system(size: 18))
                                .foregroundStyle(.secondary)
                        }

                        Text("$\(product.price, specifier: "%.2f")")
                            .font(.system(size: 26, weight: .semibold))

                        Text("Size")
                            .font(.system(size: 20, weight: .semibold))
                            .padding(.top, 8)

                        SizePicker(selected: $selectedSize, accentColor: theme.accentColor, category: product.category)

                        Button {
                            addToBag()
                        } label: {
                            Text("Add to Bag")
                                .font(.system(size: 24, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(theme.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.top, 8)

                        Button {
                            toggleHeart()
                        } label: {
                            HStack {
                                Image(systemName: product.isHearted ? "heart.fill" : "heart")
                                    .font(.system(size: 24))
                                Text(product.isHearted ? "Saved to Wish List" : "Add to Wish List")
                                    .font(.system(size: 20, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.systemGray5))
                            .foregroundStyle(product.isHearted ? .red : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }

            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                SafeBackButton { dismiss() }
            }
        }
        .interactiveDismissDisabled()
        .onAppear {
            if selectedSize.isEmpty {
                selectedSize = defaultSize
            }
        }
    }

    private var cacheManager: CacheManager {
        CacheManager(modelContext: modelContext)
    }

    private func addToBag() {
        cacheManager.addToBag(product: product, size: selectedSize)
        showConfetti = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            showConfetti = false
        }
    }

    private func toggleHeart() {
        cacheManager.toggleHeart(product: product)
    }
}
