import SwiftUI

struct CategoryPicker: View {
    @Binding var selected: String
    let accentColor: Color

    private let categories = ["hot-deals", "all", "dresses", "tops", "sweaters", "blouses", "plus-size", "accessories", "shoes"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { cat in
                    Button {
                        selected = cat
                    } label: {
                        if cat == "hot-deals" {
                            // Special exciting button for deals
                            HStack(spacing: 6) {
                                Image(systemName: "flame.fill")
                                Text("HOT DEALS")
                            }
                            .font(.system(size: 20, weight: .bold))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                selected == cat
                                    ? LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [.red.opacity(0.8), .orange.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .shadow(color: selected == cat ? .orange.opacity(0.5) : .clear, radius: 8, y: 2)
                        } else {
                            Text(displayName(for: cat))
                                .font(.system(size: 20, weight: .semibold))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(selected == cat ? accentColor : Color(.systemGray5))
                                .foregroundStyle(selected == cat ? .white : .primary)
                                .clipShape(Capsule())
                        }
                    }
                    .accessibilityLabel("\(displayName(for: cat)) category")
                }
            }
            .padding(.horizontal)
        }
    }

    private func displayName(for category: String) -> String {
        switch category {
        case "plus-size": return "Plus Size"
        case "hot-deals": return "Hot Deals"
        default: return category.capitalized
        }
    }
}
