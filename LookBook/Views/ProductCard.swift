import SwiftUI

struct ProductCard: View {
    let product: CachedProduct
    let accentColor: Color
    let onHeart: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    CachedImageView(url: product.imageUrl)
                        .frame(maxWidth: .infinity)
                        .frame(height: 360)
                        .contentShape(Rectangle())
                        .clipped()

                    // Badges
                    VStack(alignment: .leading, spacing: 6) {
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
                    .padding(12)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(product.title)
                        .font(.system(size: 22, weight: .bold))
                        .lineLimit(2)
                        .foregroundStyle(.primary)

                    if let brand = product.brand {
                        Text(brand)
                            .font(.system(size: 18))
                            .foregroundStyle(.secondary)
                    }

                    if let colour = product.colour {
                        Text(colour)
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }

                    Text("$\(product.price, specifier: "%.2f")")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .bold))
                        Text("Shop This Look")
                            .font(.system(size: 22, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(accentColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
                .padding(16)
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            Button(action: onHeart) {
                Image(systemName: product.isHearted ? "heart.fill" : "heart")
                    .font(.system(size: 28))
                    .foregroundStyle(product.isHearted ? .red : .white)
                    .shadow(radius: 3)
                    .padding(14)
            }
        }
    }
}

/// Async image loader with URLCache disk caching.
struct CachedImageView: View {
    let url: String

    var body: some View {
        if let imageUrl = URL(string: url) {
            AsyncImage(url: imageUrl) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholder
                case .empty:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundStyle(.gray)
            }
    }
}
