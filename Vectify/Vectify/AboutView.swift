import AppKit
import SwiftUI

struct AboutView: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                heroSection

                fallbackCard

                thirdPartyCard

                upstreamLinksRow

                vectifyGitHubCard

                footerSection
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 36)
            .frame(maxWidth: .infinity)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.canvas)
        .foregroundStyle(AppTheme.body)
        .navigationTitle("About")
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
                "Convert SVG folders to Android VectorDrawable XML for Jetpack Compose (`composeResources/drawable`). Built for repeatable batches, clear logs, and a fast path into your Android Studio workflow."
            )
            .font(.system(size: 13))
            .foregroundStyle(AppTheme.secondary)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
        }
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

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 16) {
            Rectangle()
                .fill(AppTheme.borderHairline)
                .frame(height: 1)
                .frame(maxWidth: .infinity)

            HStack(spacing: 6) {
                Text("Made with")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.outline)
                Image(systemName: "heart.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(red: 0.95, green: 0.35, blue: 0.45))
                Link("av-feaster", destination: VectifyGitHubLinks.authorProfile)
                    .font(.system(size: 12, weight: .semibold))
                    .tint(AppTheme.primary)
            }

            Text("© \(Calendar.current.component(.year, from: Date())) Vectify")
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.outline.opacity(0.75))
        }
        .padding(.top, 4)
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
