import SwiftUI

struct TimeProgressBar: View {
    let timeRemaining: Double
    let totalTime: Double

    var progress: CGFloat {
        max(0, min(1.0, CGFloat(timeRemaining) / CGFloat(totalTime)))
    }

    var barColor: Color {
        switch progress {
        case let p where p > 0.66:
            return DesignSystem.successColor
        case let p where p > 0.33:
            return DesignSystem.accentColor
        default:
            return DesignSystem.secondaryColor
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Time")
                    .font(DesignSystem.captionFont)
                    .foregroundColor(DesignSystem.textSecondary)
                Spacer()
                Text("\(Int(timeRemaining))s")
                    .font(DesignSystem.captionFont)
                    .foregroundColor(DesignSystem.textPrimary)
            }
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 8)

                RoundedRectangle(cornerRadius: 8)
                    .fill(barColor)
                    .frame(width: UIScreen.main.bounds.width * 0.85 * progress, height: 8)
                    .animation(.linear(duration: 0.1), value: progress)
            }
        }
        .padding(.horizontal, DesignSystem.padding)
    }
} 