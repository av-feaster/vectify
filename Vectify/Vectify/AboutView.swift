import AppKit
import SwiftUI

struct AboutView: View {
    @State private var footerShown = false

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 28) {
                    heroSection

                    whyWeBuiltCard

                    if let writingURL = VectifyGitHubLinks.authorWritingURL {
                        authorWritingCard(url: writingURL)
                    }

                    fallbackCard

                    thirdPartyCard

                    upstreamLinksRow

                    vectifyGitHubCard
                }
                .padding(.horizontal, 32)
                .padding(.top, 36)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            stickyFooterBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.canvas)
        .foregroundStyle(AppTheme.body)
        .navigationTitle("About")
        .onAppear {
            footerShown = false
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                    footerShown = true
                }
            }
        }
        .onDisappear {
            withAnimation(.easeInOut(duration: 0.32)) {
                footerShown = false
            }
        }
    }

    /// Pinned footer: stays visible while cards scroll; animates in/out with the view lifecycle.
    private var stickyFooterBar: some View {
        footerSection
            .frame(maxWidth: .infinity)
            .background {
                ZStack(alignment: .top) {
                    Rectangle()
                        .fill(AppTheme.canvas)
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.18),
                            Color.clear,
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 6)
                    .allowsHitTesting(false)
                }
            }
            .opacity(footerShown ? 1 : 0)
            .offset(y: footerShown ? 0 : 12)
            .clipped()
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 16) {
            Image(nsImage: appIconForDisplay)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AppTheme.borderSubtle, lineWidth: 1)
                )
                .shadow(color: AppTheme.primaryContainer.opacity(0.25), radius: 20, y: 8)

            Text("Vectify")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppTheme.onSurface)

            Text("VERSION \(version.uppercased())  ·  BUILD \(build)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.outline)
                .tracking(1.0)

            Text(
                "Convert SVG folders to Android VectorDrawable XML for Compose (`composeResources/drawable`). Built for batches, readable logs, and fewer heroic one-by-one imports in Android Studio."
            )
            .font(.system(size: 13))
            .foregroundStyle(AppTheme.secondary)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Why we built this

    private var whyWeBuiltCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "hand.wave")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppTheme.primaryContainer)
                Text("Why we built this")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.onSurface)
                    .tracking(0.4)
                    .textCase(.uppercase)
            }

            Text(
                """
                Kotlin Multiplatform Compose can use one shared tree—e.g. composeResources/drawable/ under commonMain—so you are not juggling separate Android vs iOS-equivalent asset folders that quietly diverge.

                Android Studio’s Vector Asset is still the patient, one-by-one path when you need its importer and edits. Vectify is batch conversion instead: same vd-tool pipeline, optional SVGO, readable logs—not a full replacement for Studio’s tooling, just a fast way to turn a folder of SVGs into drawables.
                """
            )
            .font(.system(size: 13))
            .foregroundStyle(AppTheme.onSurfaceVariant)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.borderSubtle, lineWidth: 1)
        )
    }

    private func authorWritingCard(url: URL) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "doc.text")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppTheme.primaryContainer)
                Text("Writing")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.onSurface)
                    .tracking(0.4)
                    .textCase(.uppercase)
            }
            Text("Longer posts about this stack and tooling—only if you want the story, not just the binary.")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Link("Open", destination: url)
                .font(.system(size: 12, weight: .semibold))
                .tint(AppTheme.primary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.borderSubtle, lineWidth: 1)
        )
    }

    private var appIconForDisplay: NSImage {
        let base = NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
        guard let copy = base.copy() as? NSImage else { return base }
        copy.size = NSSize(width: 128, height: 128)
        return copy
    }

    // MARK: - Fallback

    private var fallbackCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "lifepreserver")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppTheme.primaryContainer)
                Text("If something doesn’t work")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.onSurface)
                    .tracking(0.4)
                    .textCase(.uppercase)
            }

            Text(fallbackImportAttributed)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.onSurfaceVariant)
                .lineSpacing(4)
                .tint(AppTheme.primary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.primaryContainer.opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - Third-party

    private var thirdPartyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Third-party components")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppTheme.outline)
                .tracking(0.6)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 8) {
                aboutRow(title: "vd-tool", detail: "Bundled CLI (npm 4.0.2 layout) · MIT-style upstream license")
                hairline
                aboutRow(title: "Java runtime", detail: "Install JDK 8+ separately (e.g. Temurin) for the bundled converter")
                hairline
                aboutRow(title: "SVGO (optional)", detail: "Uses Node on your machine when the toggle is enabled")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.borderSubtle, lineWidth: 1)
        )
    }

    private func aboutRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.onSurface)
            Text(detail)
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Upstream (vd-tool)

    private var upstreamLinksRow: some View {
        HStack(alignment: .top, spacing: 14) {
            linkCard(
                symbol: "shippingbox",
                title: "vd-tool on npm",
                subtitle: "Upstream package used by the bundled CLI."
            ) {
                Link("Open npm", destination: URL(string: "https://www.npmjs.com/package/vd-tool")!)
            }

            linkCard(
                symbol: "chevron.left.forwardslash.chevron.right",
                title: "vd-tool source",
                subtitle: "Issues and source on GitHub."
            ) {
                Link("Open GitHub", destination: URL(string: "https://github.com/stasson/vd-tool")!)
            }
        }
    }

    // MARK: - Vectify repo & issues (GitHub)

    private var vectifyGitHubCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Vectify on GitHub")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppTheme.outline)
                .tracking(0.6)
                .textCase(.uppercase)
                .padding(.bottom, 8)

            githubLinkRow(
                symbol: "folder.fill",
                title: "Repository",
                subtitle: "Source, README, and releases.",
                destination: VectifyGitHubLinks.repository
            )
            hairline.padding(.vertical, 4)

            githubLinkRow(
                symbol: "tray.full",
                title: "Open issues",
                subtitle: "Filtered: open issues only.",
                destination: VectifyGitHubLinks.issuesOpen
            )
            hairline.padding(.vertical, 4)

            githubLinkRow(
                symbol: "sparkles",
                title: "Feature backlog",
                subtitle: "Open issues labeled enhancement (adjust the label on GitHub if needed).",
                destination: VectifyGitHubLinks.issuesFeatureFilter
            )
            hairline.padding(.vertical, 4)

            githubLinkRow(
                symbol: "plus.circle.fill",
                title: "Request a feature",
                subtitle: "Opens a new issue with the enhancement label.",
                destination: VectifyGitHubLinks.newFeatureIssue
            )
            hairline.padding(.vertical, 4)

            githubLinkRow(
                symbol: "ladybug.fill",
                title: "Report a bug",
                subtitle: "Opens a new issue with the bug label.",
                destination: VectifyGitHubLinks.newBugIssue
            )
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.borderSubtle, lineWidth: 1)
        )
    }

    private func githubLinkRow(symbol: String, title: String, subtitle: String, destination: URL) -> some View {
        Link(destination: destination) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppTheme.primaryContainer)
                    .frame(width: 28, alignment: .center)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.onSurface)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.outline)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func linkCard(
        symbol: String,
        title: String,
        subtitle: String,
        @ViewBuilder link: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(AppTheme.primaryContainer)
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.onSurface)
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            link()
                .font(.system(size: 12, weight: .semibold))
                .tint(AppTheme.primary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 148, alignment: .topLeading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.borderSubtle, lineWidth: 1)
        )
    }

    /// Compact fork / star / repo affordances (full sentence lives in `.help`).
    private var footerTripleActionIcons: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.triangle.branch")
            Image(systemName: "star.fill")
            Image(systemName: "folder.fill")
        }
        .font(.system(size: 10, weight: .semibold))
        .foregroundStyle(AppTheme.primaryContainer)
        .accessibilityLabel("Fork, star, or open the repository")
    }

    private var footerCopyrightYear: String {
        String(Calendar.current.component(.year, from: Date()))
    }

    // MARK: - Footer

    /// Single compact strip: CTA + icons · GitHub · attribution · © — with a tight two-line fallback when horizontal space is tight.
    private var footerSection: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppTheme.borderHairline)
                .frame(height: 1)
                .frame(maxWidth: .infinity)

            ViewThatFits(in: .horizontal) {
                footerStripOneLine
                footerStripTwoLines
            }
            .font(.system(size: 11))
            .padding(.horizontal, 20)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
        }
    }

    private var footerStripOneLine: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                Text("Hope you like it")
                    .foregroundStyle(AppTheme.outline)
                footerTripleActionIcons
            }
            .help("Fork, star, or get started with the repo on GitHub.")

            footerStripSeparator()

            Link("GitHub", destination: VectifyGitHubLinks.repository)
                .font(.system(size: 11, weight: .semibold))
                .tint(AppTheme.primary)

            footerStripSeparator()

            HStack(spacing: 4) {
                Text("Made with")
                    .foregroundStyle(AppTheme.outline)
                Image(systemName: "heart.fill")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color(red: 0.95, green: 0.35, blue: 0.45))
                Link("av-feaster", destination: VectifyGitHubLinks.authorProfile)
                    .font(.system(size: 11, weight: .semibold))
                    .tint(AppTheme.primary)
            }

            footerStripSeparator()

            Text(verbatim: "© \(footerCopyrightYear) Vectify")
                .foregroundStyle(AppTheme.outline.opacity(0.7))
                .font(.system(size: 10))
        }
        .lineLimit(1)
        .minimumScaleFactor(0.78)
        .frame(maxWidth: .infinity)
    }

    private var footerStripTwoLines: some View {
        VStack(alignment: .center, spacing: 4) {
            HStack(spacing: 0) {
                HStack(spacing: 6) {
                    Text("Hope you like it")
                        .foregroundStyle(AppTheme.outline)
                    footerTripleActionIcons
                }
                .help("Fork, star, or get started with the repo on GitHub.")

                footerStripSeparator()

                Link("GitHub", destination: VectifyGitHubLinks.repository)
                    .font(.system(size: 11, weight: .semibold))
                    .tint(AppTheme.primary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)

            HStack(spacing: 0) {
                HStack(spacing: 4) {
                    Text("Made with")
                        .foregroundStyle(AppTheme.outline)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color(red: 0.95, green: 0.35, blue: 0.45))
                    Link("av-feaster", destination: VectifyGitHubLinks.authorProfile)
                        .font(.system(size: 11, weight: .semibold))
                        .tint(AppTheme.primary)
                }

                footerStripSeparator()

                Text(verbatim: "© \(footerCopyrightYear) Vectify")
                    .foregroundStyle(AppTheme.outline.opacity(0.7))
                    .font(.system(size: 10))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private func footerStripSeparator() -> some View {
        Text(verbatim: "·")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(AppTheme.outline.opacity(0.32))
            .padding(.horizontal, 6)
    }

    private var hairline: some View {
        Rectangle()
            .fill(AppTheme.borderHairline)
            .frame(height: 1)
    }

    private var fallbackImportAttributed: AttributedString {
        let md = """
        Use the **Android Studio / official Android path**: **File → New → Vector Asset** (or **Resource Manager → + → Import drawables**), pick **Local file (SVG)**, and import the same SVG. Android's importer is the most compatible baseline when a generated XML won't load or renders incorrectly in preview or on device.
        """
        if let s = try? AttributedString(
            markdown: md,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return s
        }
        return AttributedString(md)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
            .frame(width: 640, height: 780)
    }
}
