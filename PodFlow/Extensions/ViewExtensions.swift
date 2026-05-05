import SwiftUI
import AuthenticationServices

// MARK: - Shimmer Loading Effect
struct ShimmerModifier: ViewModifier {
    let isAnimating: Bool
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    if isAnimating {
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .white.opacity(0.45), location: 0.4),
                                .init(color: .clear, location: 1),
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 2)
                        .offset(x: phase * geo.size.width * 2)
                        .onAppear {
                            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                                phase = 1
                            }
                        }
                    }
                }
                .clipped()
            )
    }
}

extension View {
    func shimmer(isAnimating: Bool) -> some View {
        modifier(ShimmerModifier(isAnimating: isAnimating))
    }
}

// MARK: - Conditional Modifier
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}

// MARK: - Haptic Feedback
struct HapticFeedback {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

// MARK: - Semantic Colour Tokens
// These automatically switch between light (Cool Slate) and dark (True Black) modes
extension Color {
    /// Main screen background — Cool Slate #D1D1DB (light) / True Black #000000 (dark)
    static let appBackground    = Color("AppBackground")
    /// Card / surface background — Near-white #F5F5F9 (light) / Dark Grey #1C1C1E (dark)
    static let appSurface       = Color("AppSurface")
    /// Primary text colour — adapts automatically
    static let appPrimaryText   = Color("AppPrimaryText")
    /// Secondary / caption text — adapts automatically
    static let appSecondaryText = Color("AppSecondaryText")

    // Logo accent colours
    static let accentTeal   = Color.accentTeal    // #20A0B0 — primary CTA
    static let accentOrange = Color.accentOrange  // #FF9500 — snip / secondary
    static let accentPurple = Color.accentPurple  // #AF52DE — premium
    static let accentGreen  = Color.accentGreen   // #34C759 — success / Spotify
    static let accentRed    = Color("AccentRed")     // #FF3B30 — danger / delete
    static let accentPink   = Color("AccentPink")    // #E91E8C — highlights
}

// MARK: - TimeInterval Formatting
extension TimeInterval {
    var formattedAsPlayerTime: String {
        let h = Int(self) / 3600
        let m = (Int(self) % 3600) / 60
        let s = Int(self) % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }
}

// MARK: - UIViewController + ASWebAuthenticationPresentationContextProviding
extension UIViewController: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.view.window ?? ASPresentationAnchor()
    }
}
