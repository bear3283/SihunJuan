import SwiftUI

struct StyledCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(DesignSystem.padding)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                    .fill(DesignSystem.cardColor)
                    .shadow(color: .black.opacity(0.3), radius: DesignSystem.shadowRadius, x: 0, y: 4)
            )
    }
}

struct StyledButton: View {
    let title: String
    let icon: String?
    let color: Color
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, color: Color = DesignSystem.primaryColor, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title3)
                }
                Text(title)
                    .font(DesignSystem.bodyFont)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                    .fill(color)
                    .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
} 