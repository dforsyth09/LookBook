import SwiftUI

struct SafeBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .bold))
                Text("BACK")
                    .font(.system(size: 22, weight: .bold))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.yellow)
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
