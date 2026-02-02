import SwiftUI

struct WelcomeScreen: View {
    let onStart: () -> Void
    private let theme = ThemeManager.shared
    private let duration: Double = 3.0

    @State private var fillProgress: CGFloat = 0
    @State private var autoDismissTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Handbag icon that fills with color
            ZStack {
                Image(systemName: "bag.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(Color(.systemGray4))

                Image(systemName: "bag.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(theme.accentColor)
                    .mask(alignment: .bottom) {
                        Rectangle()
                            .frame(height: 100 * fillProgress)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    }
            }
            .frame(height: 110)

            Text(theme.greeting)
                .font(.system(size: 34, weight: .bold))
                .multilineTextAlignment(.center)

            Text(theme.greetingSubtitle)
                .font(.system(size: 22))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)

            Spacer()

            Text("Getting your items ready…")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.bottom, 50)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: duration)) {
                fillProgress = 1.0
            }
            autoDismissTask = Task {
                try? await Task.sleep(for: .seconds(duration))
                if !Task.isCancelled { onStart() }
            }
        }
        .onDisappear {
            autoDismissTask?.cancel()
        }
    }
}
