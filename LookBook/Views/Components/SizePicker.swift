import SwiftUI

struct SizePicker: View {
    @Binding var selected: String
    let accentColor: Color

    private let sizes = ["S", "M", "L", "XL", "1X", "2X", "3X"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(sizes, id: \.self) { size in
                    Button {
                        selected = size
                    } label: {
                        Text(size)
                            .font(.system(size: 20, weight: .semibold))
                            .frame(minWidth: 52, minHeight: 52)
                            .background(selected == size ? accentColor : Color(.systemGray5))
                            .foregroundStyle(selected == size ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .accessibilityLabel("Size \(size)")
                }
            }
            .padding(.horizontal)
        }
    }
}
