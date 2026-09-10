import SwiftUI

/// Design tokens for Quill. Same playbook as `TK` in Tack: semantic, not literal.
public enum QL {
    public enum Radius {
        public static let xs: CGFloat = 6
        public static let sm: CGFloat = 10
        public static let md: CGFloat = 14
        public static let lg: CGFloat = 20
        public static let xl: CGFloat = 28
        public static let pill: CGFloat = 999
    }

    public enum Spacing {
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 8
        public static let sm: CGFloat = 12
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let xxl: CGFloat = 48
    }

    public enum Palette {
        // Surfaces (dark mode primary)
        public static let bgDeep      = Color(red: 0.043, green: 0.055, blue: 0.071)
        public static let surface     = Color(red: 0.078, green: 0.094, blue: 0.122)
        public static let surfaceHigh = Color(red: 0.110, green: 0.133, blue: 0.188)
        public static let surfaceElevated = Color(red: 0.149, green: 0.180, blue: 0.255)

        // Text
        public static let textStrong    = Color.primary
        public static let textMuted     = Color.secondary
        public static let textTertiary  = Color(white: 0.55)

        // Borders
        public static let border        = Color.white.opacity(0.06)
        public static let borderStrong  = Color.white.opacity(0.12)
        public static let borderLight   = Color.black.opacity(0.06)

        // Brand — Quill's rose-mauve accent (feather ink)
        public static let accent        = Color(red: 0.475, green: 0.404, blue: 0.831)   // #7967D4
        public static let accentDeep    = Color(red: 0.396, green: 0.318, blue: 0.737)   // #6551BC
        public static let accentMuted   = Color(red: 0.475, green: 0.404, blue: 0.831).opacity(0.18)
        public static let accentGlow    = Color(red: 0.475, green: 0.404, blue: 0.831).opacity(0.45)

        // Semantic
        public static let success       = Color(red: 0.290, green: 0.870, blue: 0.500)
        public static let warning       = Color(red: 0.984, green: 0.749, blue: 0.141)
        public static let danger        = Color(red: 0.973, green: 0.443, blue: 0.443)

        // Streak / gamification
        public static let streak        = Color(red: 0.984, green: 0.412, blue: 0.310)

        // Ink dot (drop of ink from the quill tip)
        public static let ink           = Color(red: 0.180, green: 0.110, blue: 0.310)
    }

    public enum Spring {
        public static let snappy: Animation = .spring(response: 0.28, dampingFraction: 0.78)
        public static let gentle: Animation = .spring(response: 0.42, dampingFraction: 0.85)
        public static let bouncy: Animation = .spring(response: 0.45, dampingFraction: 0.62)
        public static let stiff: Animation = .spring(response: 0.22, dampingFraction: 0.88)
    }

    public enum Gradient {
        public static let hero = LinearGradient(
            colors: [Palette.accent.opacity(0.30), .clear],
            startPoint: .top, endPoint: .bottom
        )
        public static let streak = LinearGradient(
            colors: [Palette.streak, Palette.warning],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    public enum Icon {
        public static let inbox     = "tray.fill"
        public static let library   = "books.vertical.fill"
        public static let highlights = "highlighter"
        public static let streak    = "flame.fill"
        public static let add       = "plus"
        public static let addBold   = "plus"
        public static let search    = "magnifyingglass"
        public static let tag       = "tag.fill"
        public static let share     = "square.and.arrow.up"
        public static let obsidian  = "diamond.fill"
        public static let archive   = "archivebox.fill"
        public static let bookmark  = "bookmark.fill"
        public static let feather   = "feather"
        public static let settings  = "gearshape.fill"
        public static let open      = "arrow.up.right.square"
    }

    public enum Typography {
        public static let heroTitle:    Font = .system(size: 34, weight: .bold, design: .serif)
        public static let heroSubtitle: Font = .system(size: 17, weight: .regular)
        public static let articleTitle: Font = .system(size: 22, weight: .semibold, design: .serif)
        public static let cardTitle:    Font = .system(size: 17, weight: .semibold, design: .default)
        public static let cardBody:     Font = .system(size: 15)
        public static let highlight:    Font = .system(size: 16, weight: .regular, design: .serif)
        public static let sectionHead:  Font = .system(size: 13, weight: .semibold)
        public static let caption:      Font = .system(size: 13)
        public static let micro:        Font = .system(size: 11)
        public static let metricLg:     Font = .system(size: 48, weight: .bold, design: .rounded)
        public static let mono:         Font = .system(size: 13, weight: .medium, design: .monospaced)
    }
}

// MARK: - View modifiers

struct QLCardStyle: ViewModifier {
    var elevated: Bool = false
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: QL.Radius.md, style: .continuous)
                    .fill(elevated ? QL.Palette.surfaceElevated : QL.Palette.surfaceHigh)
                    .overlay(
                        RoundedRectangle(cornerRadius: QL.Radius.md, style: .continuous)
                            .stroke(QL.Palette.border, lineWidth: 0.5)
                    )
            }
    }
}

struct QLAppearStyle: ViewModifier {
    @State private var appeared: Bool = false
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .onAppear {
                withAnimation(QL.Spring.gentle.delay(delay)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func qlCard(elevated: Bool = false) -> some View {
        modifier(QLCardStyle(elevated: elevated))
    }

    func qlAppear(index: Int, total: Int = 12) -> some View {
        let clamped = max(0, min(index, total - 1))
        let delay = Double(clamped) * 0.040
        return modifier(QLAppearStyle(delay: delay))
    }

    func qlHoverable() -> some View {
        #if os(macOS)
        return self.onHover { inside in
            if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
        #else
        return self
        #endif
    }
}

#if os(macOS)
import AppKit
#endif
