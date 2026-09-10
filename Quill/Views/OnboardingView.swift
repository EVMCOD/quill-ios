import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var page = 0

    private let slides: [Slide] = [
        .init(
            system: "link.circle.fill",
            tint: .indigo,
            title: "Save anything",
            subtitle: "Paste a URL, share from Safari, or capture from the menu bar. Quill fetches the title and metadata for you.",
            cta: "Continue"
        ),
        .init(
            system: "highlighter",
            tint: .orange,
            title: "Read. Highlight. Capture.",
            subtitle: "Tag articles, save passages that matter, and find them later by tag or source.",
            cta: "Continue"
        ),
        .init(
            system: "arrow.triangle.2.circlepath",
            tint: .indigo,
            title: "Sync with Obsidian",
            subtitle: "Pick your Obsidian vault. Quill writes each article as a clean markdown file with YAML frontmatter and your highlights as quotes.",
            cta: "Get started"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            TabView(selection: $page) {
                ForEach(0..<slides.count, id: \.self) { idx in
                    slideView(slides[idx]).tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            #else
            HStack(spacing: QL.Spacing.lg) {
                Button {
                    withAnimation(QL.Spring.snappy) { page = max(0, page - 1) }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(QL.Palette.surfaceHigh))
                        .foregroundStyle(QL.Palette.textStrong)
                }
                .buttonStyle(.plain)
                .disabled(page == 0).opacity(page == 0 ? 0.3 : 1)

                slideView(slides[page])
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Button {
                    withAnimation(QL.Spring.snappy) { page = min(slides.count - 1, page + 1) }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3.weight(.semibold))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(slides[page].tint))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(page == slides.count - 1)
            }
            .padding(.horizontal, QL.Spacing.xl)
            #endif

            pageDots.padding(.vertical, QL.Spacing.md)

            Button(action: advance) {
                Text(slides[page].cta)
                    .font(.callout.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, QL.Spacing.sm + 2)
                    .background(Capsule().fill(slides[page].tint))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, QL.Spacing.xl)
            .padding(.bottom, QL.Spacing.xl)
        }
        .background(QL.Palette.bgDeep.ignoresSafeArea())
    }

    private func slideView(_ s: Slide) -> some View {
        VStack(spacing: QL.Spacing.lg) {
            Spacer()
            ZStack {
                Circle()
                    .fill(s.tint.opacity(0.18))
                    .frame(width: 140, height: 140)
                Image(systemName: s.system)
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(s.tint)
            }
            Text(s.title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(QL.Palette.textStrong)
            Text(s.subtitle)
                .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundStyle(QL.Palette.textMuted)
                .frame(maxWidth: 360)
            Spacer()
        }
        .padding(.horizontal, QL.Spacing.lg)
    }

    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<slides.count, id: \.self) { idx in
                Circle()
                    .fill(idx == page ? slides[page].tint : QL.Palette.border)
                    .frame(width: 6, height: 6)
            }
        }
    }

    private func advance() {
        if page < slides.count - 1 {
            withAnimation(QL.Spring.snappy) { page += 1 }
        } else {
            onComplete()
        }
    }

    private struct Slide {
        let system: String
        let tint: Color
        let title: String
        let subtitle: String
        let cta: String
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .preferredColorScheme(.dark)
}
