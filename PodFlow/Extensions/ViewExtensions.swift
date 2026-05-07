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

// MARK: - Glass Card Modifier
// Applies a frosted glass surface — uses ultraThinMaterial on iOS 17+
// and automatically benefits from Liquid Glass rendering on iOS 26+
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 14

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 14) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
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
extension Color {
    /// Main screen background — Cool Slate #D1D1DB (light) / True Black #000000 (dark)
    static let appBackground    = Color("AppBackground")
    /// Card / surface background
    static let appSurface       = Color("AppSurface")
    /// Primary text
    static let appPrimaryText   = Color("AppPrimaryText")
    /// Secondary / caption text
    static let appSecondaryText = Color("AppSecondaryText")

    // Logo accent colours — all reference asset catalog directly
    static let accentTeal   = Color("AccentBlue")    // #20A0B0
    static let accentOrange = Color("AccentOrange")  // #FF9500
    static let accentPurple = Color("AccentPurple")  // #AF52DE
    static let accentGreen  = Color("AccentGreen")   // #34C759
    static let accentRed    = Color("AccentRed")     // #FF3B30
    static let accentPink   = Color("AccentPink")    // #E91E8C
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

// MARK: - Spotify Auth Presentation Context
final class SpotifyPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    weak var viewController: UIViewController?

    init(viewController: UIViewController?) {
        self.viewController = viewController
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return viewController?.view.window ?? UIWindow()
    }
}
