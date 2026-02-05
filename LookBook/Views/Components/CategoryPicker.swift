import SwiftUI

struct CategoryPicker: View {
    @Binding var selected: String
    let accentColor: Color

    private let row1 = ["hot-deals", "all", "dresses"]
    private let row2 = ["tops", "sweaters", "blouses"]
    private let row3 = ["plus-size", "accessories", "shoes"]

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(row1, id: \.self) { cat in
                    categoryButton(for: cat)
                }
            }
            HStack(spacing: 8) {
                ForEach(row2, id: \.self) { cat in
                    categoryButton(for: cat)
                }
            }
            HStack(spacing: 8) {
                ForEach(row3, id: \.self) { cat in
                    categoryButton(for: cat)
                }
            }
        }
        .padding(.horizontal, 12)
    }

    @ViewBuilder
    private func categoryButton(for cat: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selected = cat
            }
        } label: {
            if cat == "hot-deals" {
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                    Text("Hot Deals")
                }
                .font(.system(size: 15, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    selected == cat
                        ? LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [.red.opacity(0.8), .orange.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                )
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .shadow(color: selected == cat ? .orange.opacity(0.5) : .clear, radius: 6, y: 2)
            } else {
                Text(displayName(for: cat))
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(selected == cat ? accentColor : Color(.systemGray5))
                    .foregroundStyle(selected == cat ? .white : .primary)
                    .clipShape(Capsule())
            }
        }
        .accessibilityLabel("\(displayName(for: cat)) category")
    }

    private func displayName(for category: String) -> String {
        switch category {
        case "plus-size": return "Plus Size"
        case "hot-deals": return "Hot Deals"
        default: return category.capitalized
        }
    }
}
