import SwiftUI

// MARK: - Floating Score Effect
struct FloatingScore: View {
    let score: Int
    let position: CGPoint
    let isBonus: Bool
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1.0
    
    var body: some View {
        Text("+\(score)")
            .font(DesignSystem.headlineFont)
            .fontWeight(.bold)
            .foregroundColor(isBonus ? DesignSystem.primaryColor : DesignSystem.successColor)
            .position(x: position.x, y: position.y + offset)
            .opacity(opacity)
            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    offset = -80
                    opacity = 0
                }
            }
    }
}

// MARK: - Ripple Effect
struct RippleEffect: View {
    let position: CGPoint
    let isBonus: Bool
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0.8
    
    var body: some View {
        Circle()
            .stroke(isBonus ? DesignSystem.primaryColor : DesignSystem.secondaryColor, lineWidth: 3)
            .frame(width: 20, height: 20)
            .scaleEffect(scale)
            .opacity(opacity)
            .position(position)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    scale = 3.0
                    opacity = 0
                }
            }
    }
}

// MARK: - Particle Effect
struct ParticleEffect: View {
    let position: CGPoint
    let combo: Int
    @State private var particles: [ParticleData] = []
    
    struct ParticleData: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGPoint
        var life: Double = 1.0
        var scale: Double = 1.0
    }
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(comboColor(for: combo))
                    .frame(width: 6, height: 6)
                    .scaleEffect(particle.scale)
                    .opacity(particle.life)
                    .position(particle.position)
            }
        }
        .onAppear {
            createParticles()
            animateParticles()
        }
    }
    
    private func createParticles() {
        let particleCount = min(combo, 8)
        for _ in 0..<particleCount {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = Double.random(in: 30...60)
            let velocity = CGPoint(
                x: cos(angle) * speed,
                y: sin(angle) * speed
            )
            particles.append(ParticleData(
                position: position,
                velocity: velocity
            ))
        }
    }
    
    private func animateParticles() {
        let timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            for i in particles.indices {
                particles[i].position.x += particles[i].velocity.x * 0.016
                particles[i].position.y += particles[i].velocity.y * 0.016
                particles[i].life -= 0.02
                particles[i].scale -= 0.015
                
                if particles[i].life <= 0 {
                    particles.remove(at: i)
                    break
                }
            }
            
            if particles.isEmpty {
                timer.invalidate()
            }
        }
    }
    
    private func comboColor(for combo: Int) -> Color {
        switch combo {
        case 5...9:
            return DesignSystem.accentColor
        case 10...19:
            return Color.pink
        case 20...29:
            return Color.purple
        case 30...:
            return DesignSystem.secondaryColor
        default:
            return DesignSystem.successColor
        }
    }
} 
