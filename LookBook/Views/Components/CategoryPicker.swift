import SwiftUI

struct CategoryPicker: View {
    @Binding var selected: String
    let accentColor: Color

    private let categories = ["all", "dresses", "tops", "pants", "shoes"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { cat in
                    Button {
                        selected = cat
                    } label: {
                        Text(cat.capitalized)
                            .font(.system(size: 20, weight: .semibold))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(selected == cat ? accentColor : Color(.systemGray5))
                            .foregroundStyle(selected == cat ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .accessibilityLabel("\(cat.capitalized) category")
                }
            }
            .padding(.horizontal)
        }
    }
}
