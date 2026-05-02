import AppKit
import SwiftUI

private struct EnvironmentDiagnosticsSnapshot: Sendable {
    let java: JavaRuntimeInfo
    let vd: VdToolLocation
    let node: Bool
    let capturedAt: Date
}

/// Environment screen aligned with `stitch_svg_vector_toolbox/environment_dark_mode/code.html`.
struct EnvironmentDiagnosticsView: View {
    @State private var snapshot: EnvironmentDiagnosticsSnapshot?

    var body: some View {
        Group {
            if let snapshot {
                environmentChrome(snapshot: snapshot)
            } else {
                ProgressView("Checking environment…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppTheme.canvas)
        .foregroundStyle(AppTheme.body)
        .navigationTitle("Environment Diagnostics")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Image(systemName: "folder")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.outline)
                    .help("Folder access is granted when you pick folders in Convert.")
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.outline)
                    .help("App settings use the same toggles as on the Convert tab.")
            }
        }
        .task {
            let java = PrerequisiteChecker.javaRuntime()
            let vd = PrerequisiteChecker.vdToolLocation()
            let node = PrerequisiteChecker.nodeAvailable()
            snapshot = EnvironmentDiagnosticsSnapshot(java: java, vd: vd, node: node, capturedAt: Date())
        }
    }

    @ViewBuilder
    private func environmentChrome(snapshot: EnvironmentDiagnosticsSnapshot) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                readinessHeader(snapshot: snapshot)
                    .padding(.bottom, 28)

                statusCardsRow(snapshot: snapshot)
                    .padding(.bottom, 28)

                HStack(alignment: .top, spacing: 20) {
                    quickFixesCard
                    securityCard
                }
                .padding(.bottom, 28)

                initializationLog(snapshot: snapshot)
            }
            .frame(maxWidth: 900, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(24)
        }
    }

    // MARK: - System Readiness

    private func readinessHeader(snapshot: EnvironmentDiagnosticsSnapshot) -> some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("System Readiness")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppTheme.onSurface)
                Text("Verify tools and runtimes required for high-fidelity SVG conversion.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.outline)
            }
            Spacer(minLength: 16)
            Button {
                let t = PrerequisiteChecker.diagnosticsText(
                    java: snapshot.java,
                    vd: snapshot.vd,
                    node: snapshot.node
                )
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(t, forType: .string)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 15, weight: .medium))
                    Text("Copy Diagnostics")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(AppTheme.onPrimaryContainer)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.primaryContainer)
                )
                .shadow(color: AppTheme.primaryContainer.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Status cards (3-up)

    private func statusCardsRow(snapshot: EnvironmentDiagnosticsSnapshot) -> some View {
        HStack(alignment: .top, spacing: 16) {
            javaCard(java: snapshot.java)
            vdToolCard(vd: snapshot.vd)
            nodeCard(node: snapshot.node)
        }
    }

    private func javaCard(java: JavaRuntimeInfo) -> some View {
        let ok = java.isInstalled
        return DiagnosticStatusCard(
            accent: .java,
            categoryLabel: "Runtime",
            title: ok ? "Java (OK)" : "Java (Missing)",
            badge: ok ? "STABLE" : "CRITICAL",
            badgeStyle: ok ? .stable : .critical,
            statusLine: ok ? (java.versionLine ?? "Installed") : "JDK required for vd-tool",
            statusTone: ok ? .success : .failure,
            pathMono: java.javaHome.map { "\($0)/bin/java" } ?? java.detectionNote ?? "Not found",
            leadingBar: false
        ) {
            Image(systemName: "terminal.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color(red: 0.45, green: 0.85, blue: 0.55))
        }
    }

    private func vdToolCard(vd: VdToolLocation) -> some View {
        let ok = vd.isBundled
        let path = vd.bundledLauncherPath ?? "(run scripts/fetch-vd-tool.sh)"
        return DiagnosticStatusCard(
            accent: .internalTool,
            categoryLabel: "Internal",
            title: ok ? "vd-tool (Bundled)" : "vd-tool (Missing)",
            badge: "INTERNAL",
            badgeStyle: .internalBlue,
            statusLine: ok ? "Bundle layout OK" : "Vendor tree incomplete",
            statusTone: ok ? .success : .failure,
            pathMono: path,
            leadingBar: false
        ) {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 20))
                .foregroundStyle(AppTheme.primary)
        }
    }

    private func nodeCard(node: Bool) -> some View {
        let path = PrerequisiteChecker.nodeExecutablePath()
            ?? "Not found under /opt/homebrew/bin, /usr/local/bin, or PATH (SVGO only)"
        return DiagnosticStatusCard(
            accent: node ? .nodeOk : .nodeOptional,
            categoryLabel: "Optimizer",
            title: node ? "Node.js (OK)" : "Node.js (optional)",
            badge: node ? "READY" : "OPTIONAL",
            badgeStyle: node ? .stable : .optionalAmber,
            statusLine: node
                ? "SVGO available when the toggle is on"
                : "Not required for vd-tool. Install Node only if you use SVGO on Convert or Instant.",
            statusTone: node ? .success : .optionalNotice,
            pathMono: path,
            leadingBar: false
        ) {
            Image(systemName: "curlybraces")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(node ? Color(red: 0.45, green: 0.85, blue: 0.55) : Color(red: 0.96, green: 0.72, blue: 0.26))
        }
    }

    // MARK: - Quick fixes

    private var quickFixesCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.primary)
                Text("Quick Fixes")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.onSurface)
            }

            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "link")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.outline)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Install Java via Temurin")
                        .font(.system(size: 13, weight: .semibold))
                    Text("OpenJDK distribution for macOS (Universal Binary).")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.outline)
                    Button {
                        if let url = URL(string: "https://adoptium.net/temurin/releases/") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Visit adoptium.net")
                                .font(.system(size: 12, weight: .medium))
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(AppTheme.primary)
                    }
                    .buttonStyle(.plain)
                }
            }

            Rectangle()
                .fill(AppTheme.outlineVariant.opacity(0.35))
                .frame(height: 1)

            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "terminal")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.onSurfaceVariant)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Command Line (Homebrew)")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Quickly install the latest stable environment.")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.outline)
                    HStack {
                        Text("brew install openjdk node")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(Color(red: 0.93, green: 0.94, blue: 0.96))
                            .textSelection(.enabled)
                        Spacer(minLength: 8)
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString("brew install openjdk node", forType: .string)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.white.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                        .help("Copy command")
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(red: 0.18, green: 0.19, blue: 0.22))
                    )
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surfaceContainerHigh.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.outlineVariant.opacity(0.45), lineWidth: 1)
        )
    }

    // MARK: - Security

    private var securityCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.outline)
                Text("Security & Permissions")
                    .font(.system(size: 17, weight: .semibold))
            }
            Text(
                "Vectify runs in a sandboxed environment to protect your system. Pick input and output folders in Convert so macOS can grant access; for broader access use System Settings → Privacy & Security."
            )
            .font(.system(size: 11))
            .foregroundStyle(AppTheme.onSurfaceVariant)
            .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                sandboxPill(title: "Sandbox Status", value: "Enabled", dot: .green)
                sandboxPill(title: "File Access", value: "Restricted", dot: .amber)
            }

            VStack(spacing: 10) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 28))
                    .foregroundStyle(AppTheme.outline.opacity(0.35))
                Text("Permissions are required to write output files to folders you choose.")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.outline)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 220)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppTheme.surfaceContainerLow.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        AppTheme.outlineVariant.opacity(0.4),
                        style: StrokeStyle(lineWidth: 2, dash: [6, 5])
                    )
            )
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.outlineVariant.opacity(0.45), lineWidth: 1)
        )
    }

    private func sandboxPill(title: String, value: String, dot: SandboxDot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.outline)
                .tracking(0.4)
            HStack(spacing: 8) {
                Circle()
                    .fill(dot.color)
                    .frame(width: 8, height: 8)
                Text(value)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.onSurface)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.outlineVariant.opacity(0.35), lineWidth: 1)
        )
    }

    private enum SandboxDot {
        case green
        case amber
        var color: Color {
            switch self {
            case .green: return Color(red: 0.2, green: 0.78, blue: 0.35)
            case .amber: return Color(red: 0.96, green: 0.62, blue: 0.04)
            }
        }
    }

    // MARK: - Init log

    private func initializationLog(snapshot: EnvironmentDiagnosticsSnapshot) -> some View {
        let lines = logEntries(snapshot: snapshot)
        let timeStr = Self.timeFormatter.string(from: snapshot.capturedAt)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Initialization Log")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.outline)
                    .tracking(0.12)
                    .textCase(.uppercase)
                Spacer()
                Text("Last refresh: \(timeStr)")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.outline)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, entry in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(entry.clock)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(AppTheme.outline.opacity(0.55))
                            .frame(width: 64, alignment: .leading)
                        Text(entry.message)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(entry.color)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(AppTheme.surfaceContainerHigh.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(AppTheme.outlineVariant.opacity(0.35), lineWidth: 1)
            )
        }
    }

    private func logEntries(snapshot: EnvironmentDiagnosticsSnapshot) -> [LogLine] {
        let t0 = Self.timeFormatter.string(from: snapshot.capturedAt)
        var lines: [LogLine] = [
            LogLine(clock: t0, message: "Checking system environment…", color: AppTheme.outline.opacity(0.65)),
        ]
        if snapshot.java.isInstalled {
            let path = snapshot.java.javaHome.map { "\($0)/bin/java" } ?? "/usr/bin/java"
            let ver = snapshot.java.versionLine ?? "unknown version"
            lines.append(
                LogLine(
                    clock: t0,
                    message: "[SUCCESS] Found Java \(ver) at \(path)",
                    color: Color(red: 0.35, green: 0.88, blue: 0.48)
                )
            )
        } else {
            lines.append(
                LogLine(
                    clock: t0,
                    message: "[FAILED] No JVM found — install Temurin or set JAVA_HOME",
                    color: AppTheme.error
                )
            )
        }

        if snapshot.vd.isBundled, let p = snapshot.vd.bundledLauncherPath {
            lines.append(
                LogLine(
                    clock: t0,
                    message: "[INFO] Loaded bundled vd-tool at \(p)",
                    color: AppTheme.primary
                )
            )
        } else {
            lines.append(
                LogLine(
                    clock: t0,
                    message: "[FAILED] Bundled vd-tool missing — run fetch-vd-tool script",
                    color: AppTheme.error
                )
            )
        }

        if snapshot.node {
            if let np = PrerequisiteChecker.nodeExecutablePath() {
                lines.append(
                    LogLine(clock: t0, message: "[SUCCESS] Node.js at \(np)", color: Color(red: 0.35, green: 0.88, blue: 0.48))
                )
            }
        } else {
            lines.append(
                LogLine(
                    clock: t0,
                    message: "[INFO] Node.js not found — optional; SVGO is off unless you install Node (e.g. brew install node).",
                    color: AppTheme.primary
                )
            )
        }

        lines.append(
            LogLine(
                clock: t0,
                message: "Diagnostic report generated. Ready for conversion.",
                color: AppTheme.outline.opacity(0.55)
            )
        )
        return lines
    }

    private struct LogLine {
        let clock: String
        let message: String
        let color: Color
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()
}

// MARK: - Card chrome

private enum CardAccent {
    case java
    case internalTool
    case optimizer
    case nodeOk
    case nodeOptional
}

private enum BadgeStyle {
    case stable
    case critical
    case internalBlue
    case optionalAmber
}

private enum StatusTone {
    case success
    case failure
    case optionalNotice
}

private struct DiagnosticStatusCard<Icon: View>: View {
    let accent: CardAccent
    let categoryLabel: String
    let title: String
    let badge: String
    let badgeStyle: BadgeStyle
    let statusLine: String
    let statusTone: StatusTone
    let pathMono: String
    let leadingBar: Bool
    @ViewBuilder let icon: () -> Icon

    var body: some View {
        ZStack(alignment: .leading) {
            if leadingBar {
                Rectangle()
                    .fill(AppTheme.error)
                    .frame(width: 3)
            }
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(iconBackground)
                            .frame(width: 40, height: 40)
                        icon()
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(categoryLabel.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.onSurfaceVariant)
                            .tracking(0.4)
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.onSurface)
                    }
                    Spacer(minLength: 0)
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(badgeForeground)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(badgeBackground)
                        )
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: statusIconName)
                            .font(.system(size: 14))
                            .foregroundStyle(statusIconColor)
                        Text(statusLine)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(statusTextColor)
                    }
                    .padding(.top, 18)

                    Text(pathMono)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(leadingBar ? AppTheme.error.opacity(0.85) : AppTheme.outline)
                        .italic(leadingBar ? true : false)
                        .lineLimit(3)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(pathFieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(pathFieldStroke, lineWidth: 1)
                        )
                }
            }
            .padding(18)
            .padding(.leading, leadingBar ? 4 : 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(cardBorder, lineWidth: 1)
        )
    }

    private var statusIconName: String {
        switch statusTone {
        case .success: return "checkmark.circle.fill"
        case .failure: return "exclamationmark.circle.fill"
        case .optionalNotice: return "info.circle.fill"
        }
    }

    private var statusIconColor: Color {
        switch statusTone {
        case .success: return Color(red: 0.35, green: 0.88, blue: 0.48)
        case .failure: return AppTheme.error
        case .optionalNotice: return Color(red: 0.96, green: 0.72, blue: 0.26)
        }
    }

    private var statusTextColor: Color {
        switch statusTone {
        case .success: return AppTheme.onSurface
        case .failure: return AppTheme.error
        case .optionalNotice: return AppTheme.onSurfaceVariant
        }
    }

    private var iconBackground: Color {
        switch accent {
        case .java:
            return Color.green.opacity(0.12)
        case .internalTool:
            return AppTheme.primaryContainer.opacity(0.12)
        case .optimizer:
            return Color.red.opacity(0.1)
        case .nodeOk:
            return Color.green.opacity(0.12)
        case .nodeOptional:
            return Color(red: 0.96, green: 0.72, blue: 0.26).opacity(0.14)
        }
    }

    private var badgeForeground: Color {
        switch badgeStyle {
        case .stable: return Color(red: 0.45, green: 0.95, blue: 0.62)
        case .critical: return Color(red: 0.45, green: 0.02, blue: 0.05)
        case .internalBlue: return AppTheme.primary
        case .optionalAmber: return Color(red: 0.12, green: 0.09, blue: 0.02)
        }
    }

    private var badgeBackground: Color {
        switch badgeStyle {
        case .stable: return Color.green.opacity(0.22)
        case .critical: return AppTheme.error.opacity(0.95)
        case .internalBlue: return AppTheme.primaryContainer.opacity(0.22)
        case .optionalAmber: return Color(red: 0.96, green: 0.72, blue: 0.26).opacity(0.35)
        }
    }

    private var pathFieldBackground: Color {
        leadingBar ? AppTheme.error.opacity(0.06) : AppTheme.surface.opacity(0.9)
    }

    private var pathFieldStroke: Color {
        leadingBar ? AppTheme.error.opacity(0.25) : AppTheme.outlineVariant.opacity(0.35)
    }

    private var cardBorder: Color {
        if leadingBar, badgeStyle == .critical {
            return AppTheme.error.opacity(0.35)
        }
        return AppTheme.outlineVariant.opacity(0.45)
    }
}

