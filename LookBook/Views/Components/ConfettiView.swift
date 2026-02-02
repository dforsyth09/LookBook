import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    private let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .pink, .purple]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .allowsHitTesting(false)
            .onAppear { startConfetti(in: geo.size) }
        }
    }

    private func startConfetti(in size: CGSize) {
        particles = (0..<60).map { _ in
            ConfettiParticle(
                color: colors.randomElement()!,
                size: CGFloat.random(in: 6...12),
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -20),
                opacity: 1.0
            )
        }

        withAnimation(.easeOut(duration: 2.0)) {
            for i in particles.indices {
                particles[i].position.y += CGFloat.random(in: 400...800)
                particles[i].position.x += CGFloat.random(in: -100...100)
                particles[i].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var color: Color
    var size: CGFloat
    var position: CGPoint
    var opacity: Double
}
