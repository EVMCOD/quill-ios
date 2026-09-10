import SwiftUI

struct InboxView: View {
    @EnvironmentObject private var store: ArticleStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: QL.Spacing.md) {
                hero
                if store.inbox.isEmpty {
                    EmptyStateView(
                        system: "tray",
                        title: "Inbox is empty",
                        subtitle: "Capture a URL from any app, paste it here, or use the menubar item.",
                        tint: QL.Palette.accent
                    )
                } else {
                    ForEach(Array(store.inbox.enumerated()), id: \.element.id) { idx, article in
                        ArticleRow(article: article) {
                            withAnimation(QL.Spring.snappy) { store.toggleRead(article) }
                        }
                        .qlCard()
                        .qlAppear(index: idx)
                    }
                }
                Spacer(minLength: 80)
            }
            .padding(QL.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Inbox")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .background(QL.Palette.bgDeep.ignoresSafeArea())
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: QL.Spacing.xs) {
            Text(eyebrow)
                .font(QL.Typography.sectionHead)
                .foregroundStyle(QL.Palette.textMuted)
                .textCase(.uppercase)
                .tracking(0.6)
            Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundStyle(QL.Palette.textStrong)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(spacing: QL.Spacing.sm) {
                metricPill("\(store.inbox.count)",  label: "Inbox",     tint: QL.Palette.accent)
                metricPill("\(store.read.count)",   label: "Read",      tint: QL.Palette.success)
                metricPill("\(store.readingStreak)", label: "Streak",    tint: QL.Palette.streak)
            }
            .padding(.top, QL.Spacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, QL.Spacing.md)
    }

    private var eyebrow: String {
        let count = store.inbox.count
        return count == 0
            ? "Reading queue"
            : count == 1 ? "1 article waiting" : "\(count) articles waiting"
    }

    private func metricPill(_ value: String, label: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(QL.Palette.textMuted)
                .textCase(.uppercase)
                .tracking(0.4)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(QL.Palette.textStrong)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .padding(.horizontal, QL.Spacing.md)
        .padding(.vertical, QL.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: QL.Radius.md)
                .fill(QL.Palette.surfaceHigh)
                .overlay(
                    RoundedRectangle(cornerRadius: QL.Radius.md)
                        .stroke(tint.opacity(0.25), lineWidth: 0.5)
                )
        )
    }
}

private struct ArticleRow: View {
    let article: Article
    let onToggleRead: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: QL.Spacing.sm) {
            Button(action: onToggleRead) {
                Image(systemName: article.status == .read ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(article.status == .read ? QL.Palette.success : QL.Palette.accent)
                    .padding(.top, 2)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .qlHoverable()

            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(QL.Typography.articleTitle)
                    .foregroundStyle(article.status == .read ? QL.Palette.textTertiary : QL.Palette.textStrong)
                    .strikethrough(article.status == .read)
                    .lineLimit(2)
                if !article.summary.isEmpty {
                    Text(article.summary)
                        .font(QL.Typography.cardBody)
                        .foregroundStyle(QL.Palette.textMuted)
                        .lineLimit(2)
                }
                HStack(spacing: QL.Spacing.xs) {
                    if !article.siteName.isEmpty {
                        Pill(system: QL.Icon.bookmark, text: article.siteName, tint: QL.Palette.accentMuted)
                    }
                    if article.highlights.count > 0 {
                        Pill(system: QL.Icon.highlights, text: "\(article.highlights.count)", tint: QL.Palette.warning.opacity(0.25))
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, QL.Spacing.sm)
        .padding(.horizontal, QL.Spacing.sm)
        .contentShape(Rectangle())
    }
}

private struct Pill: View {
    let system: String
    let text: String
    let tint: Color
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: system).font(.caption2)
            Text(text).font(.caption2.weight(.medium))
        }
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(Capsule().fill(tint))
        .foregroundStyle(QL.Palette.textStrong)
    }
}
