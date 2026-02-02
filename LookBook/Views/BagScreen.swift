import SwiftUI
import SwiftData

struct BagScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BagItem.addedAt, order: .reverse) private var bagItems: [BagItem]

    @State private var showClearConfirmation = false
    @State private var navigateToProduct: CachedProduct?

    private let theme = ThemeManager.shared

    var body: some View {
        NavigationStack {
            Group {
                if bagItems.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "bag")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("Your bag is empty")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text("Add something you love!")
                            .font(.system(size: 20))
                            .foregroundStyle(.tertiary)
                        Spacer()
                    }
                } else {
                    VStack(spacing: 0) {
                        List {
                            ForEach(bagItems) { item in
                                Button {
                                    let cm = CacheManager(modelContext: modelContext)
                                    if let product = cm.product(byId: item.productId) {
                                        navigateToProduct = product
                                    }
                                } label: {
                                    HStack(spacing: 14) {
                                        CachedImageView(url: item.productImageUrl)
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.productTitle)
                                                .font(.system(size: 20, weight: .semibold))
                                                .lineLimit(2)
                                            Text("Size: \(item.selectedSize)")
                                                .font(.system(size: 18))
                                                .foregroundStyle(.secondary)
                                            Text("$\(item.productPrice, specifier: "%.2f")")
                                                .font(.system(size: 20, weight: .medium))
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                            }
                            .onDelete(perform: deleteItems)

                            HStack {
                                Text("Total")
                                    .font(.system(size: 24, weight: .bold))
                                Spacer()
                                Text("$\(total, specifier: "%.2f")")
                                    .font(.system(size: 24, weight: .bold))
                            }
                            .padding(.vertical, 8)
                            .listRowBackground(Color(.systemGray6))
                        }
                        .listStyle(.plain)

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
                        .confirmationDialog("Remove all items from your bag?", isPresented: $showClearConfirmation, titleVisibility: .visible) {
                            Button("Remove All", role: .destructive) {
                                CacheManager(modelContext: modelContext).clearBag()
                            }
                        }
                    }
                }
            }
            .navigationDestination(item: $navigateToProduct) { product in
                ProductDetailScreen(product: product)
            }
            .navigationTitle("My Bag")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("My Bag")
                        .font(.system(size: 28, weight: .bold))
                }
            }
        }
    }

    private var total: Double {
        bagItems.reduce(0) { $0 + $1.productPrice }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(bagItems[index])
        }
        try? modelContext.save()
    }
}
