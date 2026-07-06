import SwiftUI

public struct DisintegrationEffect: ViewModifier {
    var isDeleted: Bool
    
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var xOffset: CGFloat
        var yOffset: CGFloat
        var opacity: Double
        var scale: CGFloat
    }
    
    public func body(content: Content) -> some View {
        ZStack {
            if !isDeleted {
                content
            } else {
                ForEach(particles) { particle in
                    content
                        .mask(
                            Rectangle()
                                .frame(width: 20, height: 20)
                                .offset(x: particle.xOffset, y: particle.yOffset)
                        )
                        .scaleEffect(particle.scale)
                        .offset(x: particle.xOffset, y: particle.yOffset)
                        .opacity(particle.opacity)
                }
            }
        }
        .onChange(of: isDeleted) { _, newValue in
            if newValue {
                createParticles()
                withAnimation(.easeOut(duration: 1.5)) {
                    for i in 0..<particles.count {
                        particles[i].xOffset += CGFloat.random(in: -150...150)
                        particles[i].yOffset += CGFloat.random(in: -150...150)
                        particles[i].opacity = 0
                        particles[i].scale = 0.1
                    }
                }
            } else {
                particles.removeAll()
            }
        }
    }
    
    private func createParticles() {
        var newParticles: [Particle] = []
        for x in stride(from: -50, through: 50, by: 20) {
            for y in stride(from: -50, through: 50, by: 20) {
                newParticles.append(Particle(
                    xOffset: CGFloat(x),
                    yOffset: CGFloat(y),
                    opacity: 1.0,
                    scale: 1.0
                ))
            }
        }
        particles = newParticles
    }
}

public extension View {
    func disintegrationEffect(isDeleted: Bool) -> some View {
        self.modifier(DisintegrationEffect(isDeleted: isDeleted))
    }
}
