import SwiftUI

struct EmptyStateView: View {
    let system: String
    let title: String
    let subtitle: String
    var tint: Color = QL.Palette.accent
    var action: (label: String, perform: () -> Void)? = nil

    init(system: String, title: String, subtitle: String) {
        self.system = system
        self.title = title
        self.subtitle = subtitle
    }

    init(system: String, title: String, subtitle: String, tint: Color) {
        self.system = system
        self.title = title
        self.subtitle = subtitle
        self.tint = tint
    }

    init(system: String, title: String, subtitle: String, tint: Color = QL.Palette.accent, actionLabel: String, perform: @escaping () -> Void) {
        self.system = system
        self.title = title
        self.subtitle = subtitle
        self.tint = tint
        self.action = (actionLabel, perform)
    }

    var body: some View {
        VStack(spacing: QL.Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [tint.opacity(0.45), tint.opacity(0.0)],
                            center: .center, startRadius: 6, endRadius: 130
                        )
                    )
                    .frame(width: 220, height: 220)
                ZStack {
                    Circle()
                        .fill(QL.Palette.surfaceHigh)
                        .frame(width: 96, height: 96)
                    Image(systemName: system)
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(tint)
                }
            }
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(QL.Palette.textStrong)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundStyle(QL.Palette.textMuted)
                .frame(maxWidth: 340)
                .padding(.horizontal, QL.Spacing.lg)
            if let action {
                Button(action: { action.perform() }) {
                    Label(action.label, systemImage: "plus.circle.fill")
                        .font(.callout.weight(.semibold))
                        .padding(.horizontal, QL.Spacing.lg)
                        .padding(.vertical, QL.Spacing.sm + 2)
                        .background(Capsule().fill(tint))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .padding(.top, QL.Spacing.xs)
            }
        }
        .padding(.vertical, QL.Spacing.xxl)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    EmptyStateView(
        system: "tray",
        title: "Inbox is empty",
        subtitle: "Paste an article URL to start your reading queue.",
        tint: QL.Palette.accent,
        actionLabel: "Add article"
    ) {}
    .background(QL.Palette.bgDeep)
    .preferredColorScheme(.dark)
}
