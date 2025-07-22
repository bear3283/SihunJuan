import SwiftUI

// MARK: - Design System
struct DesignSystem {
    // Colors - Space style
    static let primaryColor = Color(red: 0.0, green: 0.8, blue: 1.0) // Cyan blue
    static let secondaryColor = Color(red: 1.0, green: 0.2, blue: 0.8) // Neon pink
    static let accentColor = Color(red: 0.9, green: 0.9, blue: 0.2) // Bright yellow
    static let successColor = Color(red: 0.0, green: 1.0, blue: 0.6) // Neon green
    static let backgroundColor = Color(red: 0.02, green: 0.02, blue: 0.1) // Deep space color
    static let spaceDeep = Color(red: 0.05, green: 0.05, blue: 0.15) // Deeper space color
    static let cardColor = Color.white.opacity(0.1)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    
    // Typography
    static let titleFont = Font.system(size: 32, weight: .bold, design: .rounded)
    static let headlineFont = Font.system(size: 24, weight: .semibold, design: .rounded)
    static let bodyFont = Font.system(size: 18, weight: .medium, design: .rounded)
    static let captionFont = Font.system(size: 14, weight: .regular, design: .rounded)
    
    // Spacing - reduced shadow
    static let cornerRadius: CGFloat = 16
    static let shadowRadius: CGFloat = 4  // Reduced from 8 to 4
    static let padding: CGFloat = 20
} 